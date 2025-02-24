#!/bin/bash
#
# Calculates the average daily low and high temparatures for the first of each month.
# Uses the government of Canada historical weather data. 
#
# See: https://climate.weather.gc.ca/historical_data/search_historic_data_e.html
#
#
# 
bulkDataSite='https://climate.weather.gc.ca/climate_data/bulk_data_e.html'
#dataFormat='xml'
dataFormat='csv'
# timeframe='1' # hourly
timeframe='2' # daily
# timeframe='3' # monthly
repository="./repository"

# Set the range of years to include in the calculations (inclusive)
startYear=2000
endYear=2024

##
# The name of the data table for each repository file.
# This is simply the name of the file without the extension.
function tableName() {
    local year="$1"
 
    echo "daily_${year}"
}

##
# The name of the repository file, including the repository
# directory and table name and extension.
function repositoryFileName() {
    local year="$1"
 
    echo "$repository/$(tableName "$year").$dataFormat"
}

##
# Query the Canandian weather service for historical data.
# Gets one file per year containing the daily data for every day of every month.
#
# This falls apart for 2012, since the data for 2012 is split into two stationId's.
# The first 10 months of data are in one stationId, the last 2 months in another.
# This special case is not handled.
#
# This only works for Halifax right now.
#
function downloadDailyDataByYear() {
    local year="$1"
    local fileName
    local stationId

    fileName=$(repositoryFileName "$year")
    
    if [[ -f "$fileName" ]] ; then
        echo "$fileName already downloaded."
    else
        echo "Downloading data for $year"

        # The stationId is the identifier for the weather station.
        # See https://collaboration.cmc.ec.gc.ca/cmc/climate/Get_More_Data_Plus_de_donnees/Station%20Inventory%20EN.csv
        # for the complete list.
        #
        # There may be multiple stations for the same location. Each station may have different years of data.
        #
        # Therefore, select the correct Halifax station depending in the year.
        # Station 50620 has the last 2 months of 2012 up to current.
        # Station 6358 has 1953 to 2012 according to the list linked above.
        #
        # A Fragment from the file linked above:
        #
        # "Name","Province","Climate ID","Station ID","WMO ID","TC ID","Latitude (Decimal Degrees)","Longitude (Decimal Degrees)","Latitude","Longitude","Elevation (m)","First Year","Last Year","HLY First Year","HLY Last Year","DLY First Year","DLY Last Year","MLY First Year","MLY Last Year"
        # "HALIFAX","NOVA SCOTIA","8202198","6355","","","44.65","-63.6","443900000","-633600000","29.6","1871","1933","","","1871","1933","1871","1933"
        # "HALIFAX","NOVA SCOTIA","8202200","6356","","","44.65","-63.57","443900000","-633400000","31.7","1939","1974","1953","1963","1939","1974","1939","1974"
        # "HALIFAX CITADEL","NOVA SCOTIA","8202220","6357","","","44.65","-63.58","443900000","-633500000","70.1","1933","2002","","","1933","2002","1933","2002"
        # "HALIFAX COMMONS","NOVA SCOTIA","8202221","49128","","AHF","44.63","-63.58","443800000","-633500000","44","2010","2011","2010","2011","","","",""
        # "HALIFAX DOCKYARD","NOVA SCOTIA","8202240","43405","71328","AHD","44.66","-63.58","443919000","-633436000","3.8","2004","2025","2004","2025","2018","2025","",""
        # "HALIFAX STANFIELD INT'L A","NOVA SCOTIA","8202249","53938","","YHZ","44.88","-63.51","445252000","-633031000","145.4","2019","2025","2019","2025","2019","2025","",""
        # "HALIFAX STANFIELD INT'L A","NOVA SCOTIA","8202250","6358","71395","YHZ","44.88","-63.5","445248060","-633000050","145.4","1953","2012","1961","2012","1953","2012","1953","2012"
        # "HALIFAX STANFIELD INT'L A","NOVA SCOTIA","8202251","50620","71395","YHZ","44.88","-63.51","445252000","-633031000","145.4","2012","2025","2012","2025","2012","2025","",""
        # "HALIFAX KOOTENAY","NOVA SCOTIA","8202252","43124","71326","AHK","44.59","-63.55","443515500","-633303000","52","2004","2025","2004","2025","2018","2025","",""
        # "HALIFAX WINDSOR PARK","NOVA SCOTIA","8202255","43403","71327","AHW","44.66","-63.61","443925000","-633632000","51","2004","2025","2004","2025","2018","2025","",""


        stationId='50620' # Halifax Stanfield International Airport
        if [[ "$year" -lt 2013 ]] ; then
            stationId="6358"
        fi
        wget -qO "$fileName" --content-disposition "${bulkDataSite}?format=${dataFormat}&stationID=${stationId}&Year=${year}&timeframe=${timeframe}&submit=Download+Data"
    fi
}

##
# Read the weather data files and select only the data we want on the first day of each month.
#
# Disable the shellcheck: Expressions don't expand in single quotes, use double quotes for that.
# This is the behaviour we want in this function.
# shellcheck disable=SC2016
function queryFirstDayOfMonth() {
    local year="$1"

    echo 'SELECT Year, '
    echo     'Month, '
    echo     '`Min Temp (°C)`, '
    echo     '`Max Temp (°C)`, '
    echo     '`Mean Temp (°C)` '
    echo "FROM $(tableName "$year") "
    echo 'WHERE Day="01";'
}

##
# Query the first day of each month and output a new table.
# Ignores all the other days.
function processRepositoryDataByYear() {
    local year="$1"

    csvq --repository ./repository --format CSV "$(queryFirstDayOfMonth "$year")"
}

if [[ ! -d "$repository" ]] ; then
    echo "No repository directory ($repository) found."
    echo "You may need to create a new empty directory, or change the repository location"
    exit 1
fi

# Temporarily store the data for the first day of each month
# so it can be aggregated across years later.
tmpData=first_days.csv
# Output a header line for the first day table
echo '"year","month","min","max","mean"' > "$tmpData"

for year in $(seq $startYear $endYear) ; do
    downloadDailyDataByYear "${year}"

    # The tail command is used to remove the header from the output CSV file.
    # The header is particularly ugly, plus we are concatenating all the year data together which would
    # cause a bunch of extra header lines in the result file.
    processRepositoryDataByYear "$year"  | tail -n +2 >> "$tmpData"
done

##
# Processes the first day of the month temporary data to aggregate it by year.
#
# Disable the shellcheck: Expressions don't expand in single quotes, use double quotes for that.
# This is the behaviour we want in this function.
# shellcheck disable=SC2016
function queryAveragesByYear() {
    echo 'SELECT `month`, '
    echo '    ROUND(AVG(`min`), 1) as `avg_min`, '
    echo '    ROUND(AVG(`max`), 1) as `avg_max`, '
    echo '    ROUND(AVG(`mean`), 1) as `avg_mean`, '
    echo '    ROUND(MIN(`min`), 1) as `lowest`, '
    echo '    ROUND(MAX(`max`), 1) as `highest` '
    echo 'FROM first_days '
    echo 'GROUP BY `month` ORDER BY `month`;'
}

echo
echo "Aggregated temparatures in degrees celcius of the first day of the month"
echo "for the years $startYear to $endYear inclusive."
echo
csvq "$(queryAveragesByYear)"
