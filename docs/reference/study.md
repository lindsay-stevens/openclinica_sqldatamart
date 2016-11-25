# study

## Overview
The scripts described in this section are responsible for the creation of 
study schema objects.

The scripts are executed in the following order.

- [dm_create_study_schemas](#dm_create_study_schemas)
- [dm_create_study_common_matviews](#dm_create_study_common_matviews)
- [dm_create_study_itemgroup_matviews](#dm_create_study_itemgroup_matviews)

## Scripts

### dm_create_study_schemas

#### Purpose
Create a schema for each study listed in dm.metadata.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_study_common_matviews

#### Purpose
Create a copy of each dm matview in each study schema, filtered for that study.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_study_itemgroup_matviews

#### Purpose
Create a matviews in each study schema for each item group containing item columns.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.