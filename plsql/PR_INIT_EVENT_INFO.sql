CREATE OR REPLACE PROCEDURE ISS.PR_INIT_EVENT_INFO (
  I_EVENT_INFO IN OUT EVENT_INFO_TYPE
) IS
BEGIN
  I_EVENT_INFO := new EVENT_INFO_TYPE('', '', '', 0, 0, '', 0, '', 0, 0, 0, 0);
END;