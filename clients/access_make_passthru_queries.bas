Attribute VB_Name = "mod_make_passthru_queries"
Option Compare Database

Function make_passthru_queries(study_schema_name As String, connection_string As String)

' creates a set of pass through queries for each postgres object in the study schema.

' the objects are the matviews listed in pg_matviews for that schema.
' call with a RunCode macro, or in the immediate pane with ?make_passthru_queries(params)

' Required params:
' :param study_schema_name: the name of the postgres schema to create objects from
' :param connection_string: either an odbc connection string or FILEDSN=//path/to/file.dsn


Dim local_db                  As DAO.Database
Dim object_ws                As DAO.Workspace
Dim object_db                As DAO.Database
Dim object_sql               As String
Dim object_rs                As DAO.Recordset
Dim object_qdf               As DAO.QueryDef
Dim object_exists_sql         As String
Dim object_exists_rs          As DAO.Recordset
Dim object_exists_bool        As Boolean

' open a connection to postgres so the list of objects can be retrieved
Set object_ws = DBEngine(0)
Set object_db = object_ws.OpenDatabase("", False, False, connection_string)

' populate a local recordset with the list of objects in the schema
Set local_db = CurrentDb
object_sql = "SELECT pg_matviews.matviewname AS objectname FROM pg_matviews " _
        & "WHERE pg_matviews.schemaname=" & Chr(39) & study_schema_name & Chr(39)
Set object_rs = object_db.OpenRecordset(object_sql)

' loop through each object to make pass through queries for each
object_rs.MoveFirst

Do Until object_rs.EOF

    ' check if the query exists in the local db already
    object_exists_sql = "SELECT MSysObjects.Name FROM MSysObjects " _
            & " WHERE MSysObjects.Name=" & Chr(34) & object_rs("objectname") & Chr(34)
    Set object_exists_rs = local_db.OpenRecordset(object_exists_sql)
    object_exists_bool = (object_exists_rs.RecordCount <> 0)

    ' if the query exists already then drop it
    If object_exists_bool = True Then
        DoCmd.RunSQL "DROP TABLE " & object_rs("objectname")
    End If

    ' create a query def for the current object
    Set object_qdf = local_db.CreateQueryDef(object_rs("objectname"))
    With object_qdf
        .SQL = "SELECT * FROM " & study_schema_name & "." & object_rs("objectname")
        .connect = "ODBC;" & connection_string
    End With

    ' clear the query def and move to the next object
    Set object_qdf = Nothing
    object_rs.MoveNext

Loop

Application.RefreshDatabaseWindow

' clean up
object_rs.Close
local_db.Close
Set object_rs = Nothing
Set local_db = Nothing
' Access doesn't allow closing ODBC connections, so that will happen on close

End Function

