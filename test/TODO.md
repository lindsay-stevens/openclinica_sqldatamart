## todo

- Finish adding updated version of old common views
    - Include unique index in all matviews for concurrent refresh
- Fix/update Stata and SAS export code accordingly
    - Stata uses new views but query execution is very slow, possibly due to left join of metadata on response sets
- Fix/update maintenance scripts accordingly
    - Possibly include output of script for refreshing studies in separate transactions, which is immediately read back in and executed as batch.
- Performance test view-only clinicaldata db
    - If bad, add unique index for matview concurrent refresh
    - Maybe have it as optional for small dbs
- Further testing improvements:
    - Add more coverage,
    - Add CI build configuration
    - Add a performance test database with a large amount of studies (over 10), and item data (over 500,000)
- Simpler / cross platform build scripts


## completed

- New identifier naming strategy to ensure uniques within an item group, handling:
    - multi-choice items with duplicates choices
    - multi-choice items with choices that have invalid identifier characters
    - stata / sas naming requirements of less than 32 character variable names
- Automatically partition item groups into maximum 200 columns each
- Handle data type casting failures, which may occur due to:
    - Use of null value codes with items that are not strings
    - Invalid study designs e.g. where DATE is the type for an INT choice list.
- Improve development process / add test framework
