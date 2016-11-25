# dm

## Overview
The scripts described in this section are responsible for the creation of 
objects in the dm (datamart) schema. 

The scripts are executed in the following order.

- [dm_create_dm_response_sets](#dm_create_dm_response_sets)
- [dm_create_dm_metadata](#dm_create_dm_metadata)
- [dm_create_dm_metadata_event_crf_ig](#dm_create_dm_metadata_event_crf_ig)
- [dm_create_dm_metadata_crf_ig_item](#dm_create_dm_metadata_crf_ig_item)
- [dm_create_dm_metadata_study](#dm_create_dm_metadata_study)
- [dm_create_dm_clinicaldata](#dm_create_dm_clinicaldata)
- [dm_create_dm_subjects](#dm_create_dm_subjects)
- [dm_create_dm_subject_event_crf_status](#dm_create_dm_subject_event_crf_status)
- [dm_create_dm_subject_event_crf_expected](#dm_create_dm_subject_event_crf_expected)
- [dm_create_dm_subject_event_crf_join](#dm_create_dm_subject_event_crf_join)
- [dm_create_dm_discrepancy_notes_all](#dm_create_dm_discrepancy_notes_all)
- [dm_create_dm_discrepancy_notes_parent](#dm_create_dm_discrepancy_notes_parent)
- [dm_create_dm_subject_groups](#dm_create_dm_subject_groups)
- [dm_create_dm_response_set_labels](#dm_create_dm_response_set_labels)
- [dm_create_dm_user_account_roles](#dm_create_dm_user_account_roles)
- [dm_create_dm_sdv_status_history](#dm_create_dm_sdv_status_history)

## Scripts

### dm_create_dm_response_sets

#### Purpose
Create a materialized view containing item response set data.

#### Description
In a series of subqueries, split the comma separated values list in option_text
into an array. To retain the value ordering, use generate_subscripts. In a
separate series of subqueries, do the same for the csv list in options_values.
Join the results.

Columns:
- version_id: version of the response set.
- response_set_id: database id of the response set.
- label: label specified for the response set in the CRF spreadsheet.
- option_text: the response option label displayed in the CRF.
- option_value: the response option value saved for the CRF.
- option_order: the order of the response option within the response set.

#### Parameters
None.

#### Returns
Void.

### dm_create_dm_metadata

#### Purpose
Create a materialized view containing study metadata from study to item.

#### Description
Each output row corresponds to a combination of an item + CRF + event + study.

In the study_with_status common table expression, retrieve details for each 
study including the status. 

In the metadata_no_multi CTE, place the parent study details if one exists, 
or the current study. Join along the object hierarchy from study to item. In a
subquery, retrieve the details of items used in simple conditional displays. 
Only output rows where none of the objects in the hierarchy have been removed.

In the main query, output the metadata_no_multi rows, excluding rows for items
which may have multiple values (multi-select, checkbox). Use the 
metadata_no_multi results to generate additional rows for each multi-value item
value, appending the item value to the item_oid and item_name. Union the 
results. 

Columns:
- study_name: study display name
- study_status: study status
- study_date_created: date study was created
- study_date_updated: date study was last updated
- site_oid: unique oid of the study
- site_name: site name - should always be the study name
- event_oid: unique oid of the event
- event_order: the display order of the event in the subject matrix
- event_name: display name of the event
- event_date_created: date event was created
- event_date_updated: date event was last updated
- event_repeating: event allows repetition or not
- crf_parent_oid: unique oid of the parent crf
- crf_parent_name: display name of the parent crf
- crf_parent_date_created: date parent crf was created
- crf_parent_date_updated: date parent crf was last updated
- crf_version: version name of the crf version
- crf_version_oid: unique oid of the crf version
- crf_version_date_created: date crf version was created
- crf_version_date_updated: date crf version was last updated
- crf_is_required: whether crf is required in the event
- crf_is_double_entry: whether crf requires double data entry in the event
- crf_is_hidden: whether the crf is hidden in the event
- crf_null_values: which if any null value codes to allow for the crf in the event
- crf_section_label: short name for the crf section
- crf_section_title: long name for the crf section
- item_group_oid: unique oid of the item group
- item_group_name: display name of the item group
- item_form_order: order of the item within the crf
- item_oid: unique oid of the item
- item_name: internal name of the item
- item_oid_multi_original: for multi-valued items, the original item oid
- item_name_multi_original: for multi-valued items, the original item name
- item_units: units displayed for item
- item_data_type: internal data type of the item
- item_response_type: crf widget type of the item
- item_response_set_label: label of response set with the item choices
- item_response_set_id: database id of the item response set
- item_response_set_version: version of the item response set
- item_question_number: question number displayed for the item
- item_description: internal description of item
- item_header: header text displayed for the item
- item_subheader: subheader text displayed for the item
- item_left_item_text: question text displayed on the left of the item widget
- item_right_item_text: question text displayed on the right of the item widget
- item_regexp: regular expression used to validate the item value
- item_regexp_error_msg: error message to show if item regexp validation fails
- item_required: whether item requires a value when it is shown
- item_default_value: default value populated for the item on first data entry
- item_response_layout: orientation of item choices for radio and checkboxes
- item_width_decimal: item value width and decimal places allowed
- item_show_item: default visibility of item on crf
- item_scd_control_item_oid: simple conditional display control item oid
- item_scd_control_item_option_value: value of control item to show this item for
- item_scd_control_item_option_text: value label of control item value
- item_scd_validation_message: error message control item value validation fails

#### Parameters
None.

#### Returns
Void.

### dm_create_dm_metadata_event_crf_ig

#### Purpose
Create a materialized view containing study metadata from study to item group.

#### Description
Limit the dm.metadata query to unique values to the item group level in the 
object hierarchy. 

Columns:
Same as for dm.metadata, excluding all item-specific values.

#### Parameters
None.

#### Returns
Void.

### dm_create_dm_metadata_crf_ig_item

#### Purpose
Create a materialized view containing study metadata from crf to item.

#### Description
Limit the dm.metadata query to unique values to the crf level to item level in
the object hierarchy. 

Columns:
Same as for dm.metadata, excluding all event-specific values.

#### Parameters
None.

#### Returns
Void.

### dm_create_dm_metadata_study

#### Purpose
Create a materialized view containing study metadata at the study level only.

#### Description
Limit the dm.metadata query to unique values at the study level of the object
hierarchy only.

Columns:
Same as for dm.metadata, excluding all values for objects below the study.

#### Parameters
None.

#### Returns
Void.

### dm_create_dm_clinicaldata

#### Purpose
Create a materialized view containing study data.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_subjects

#### Purpose
Create a materialized view containing subject details.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_subject_event_crf_status

#### Purpose
Create a materialized view containing event and crf status details.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_subject_event_crf_expected

#### Purpose
Create a materialized view containing events and crfs possible for a subject.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_subject_event_crf_join

#### Purpose
Create a materialized view containing events and crfs statuses with possible.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_discrepancy_notes_all

#### Purpose
Create a materialized view containing all parent and child discrepancy notes.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_discrepancy_notes_parent

#### Purpose
Create a materialized view containing parent discrepancy notes only.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_subject_groups

#### Purpose
Create a materialized view containing subject grouping details.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_response_set_labels

#### Purpose
Create a materialized view containing crfs, items and their response set options.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_user_account_roles

#### Purpose
Create a materialized view containing all user accounts and role details.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.

### dm_create_dm_sdv_status_history

#### Purpose
Create a materialized view containing crf sdv status and sdv history, if any.

#### Description


Columns:


#### Parameters
None.

#### Returns
Void.