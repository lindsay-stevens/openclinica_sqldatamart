CREATE VIEW dm.user_management_functions AS
  SELECT
    dm_users_new_oc_user_new_login_role(),
    dm_users_removed_oc_user_alter_role_nologin(),
    dm_users_restored_oc_user_alter_role_login(),
    dm_users_available_role_oc_user_grant_to_role(),
    dm_users_removed_role_oc_user_revoke_from_role();