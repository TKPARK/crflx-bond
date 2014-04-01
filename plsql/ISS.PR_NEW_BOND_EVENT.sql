CREATE OR REPLACE PROCEDURE ISS.PR_NEW_BOND_EVENT (
--I_EVENT_IO            IN OUT EVENT_IO     -- EVNET I/O Object
  I_EVENT_DATE          IN     CHAR(8)      -- �ŷ�����(EVENT �߻���)
, I_FUND_CODE           IN     CHAR(10)     -- �ݵ��ڵ�
, I_BOND_CODE           IN     CHAR(12)     -- �����ڵ�
, I_SETL_DATE           IN     CHAR(8)      -- ��������
, I_TRD_QTY             IN     NUMBER(22)   -- �ŷ�����
, I_TRD_PRICE           IN     NUMBER(22)   -- �ŷ��ܰ�
, I_SELL_RT             IN     NUMBER(10,5) -- �ŵ���
, I_TRD_TYPE_CD         IN     CHAR(1)      -- �Ÿ������ڵ�(1.�μ�, 2.���ż�)
, I_GOODS_BUY_SELL_SECT IN     CHAR(1)      -- ��ǰ�ż��ŵ�����(1.��ǰ�ż�, 2.��ǰ�ŵ�)
, I_STT_TERM_SECT       IN     CHAR(1)      -- �����Ⱓ����(0.����, 1.����)
, O_RESULT_MSG          IN OUT CHAR(500)    -- ��� �޽���
) IS
  --
  T_EVENT_INFO   PKG_EIR_NESTED_NSC.EVENT_INFO_TYPE; -- TYPE : EVENT INFO
  T_EIR_CALC     PKG_EIR_NESTED_NSC.EIR_CALC_INFO;   -- TYPE : EIR CALC INFO
  T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;      -- ROWTYPE : �̺�Ʈ ��� TABLE
  T_BOND_TRADE   BOND_TRADE%ROWTYPE;                 -- ROWTYPE : �ŷ����� TABLE
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;               -- ROWTYPE : �ܰ� TABLE
BEGIN
  -- 1)�Է°� ����
  PR_INPUT_VALUE_CHECK(I_EVENT_IO);
  
  
  
  -- 2)�����ʱ�ȭ
  --   * Object���� �ʱ�ȭ �� Default������ ������
  T_EVENT_RESULT := FN_INIT_EVENT_RESULT();
  T_BOND_TRADE := FN_INIT_BOND_TRADE();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  
  
  
  -- 3-1)�̺�Ʈ ó�� INPUT ����
  PR_CALC_BOND_INFO(I_EVENT_IO, T_EIR_CALC, T_EVENT_INFO);
  
  -- 3-2)�̺�Ʈ ó�� ���ν��� ȣ��
  --   * �ż�, �ŵ�, �ݸ�����, �ջ� �� �̺�Ʈ ó�� ���ν���
  --   * �������, �����帧 ����, EIR����, ��ǥ ���� ���� ó����
  PKG_EIR_NESTED_NSC.PR_EVENT(T_EIR_CALC, T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  -- 4)�������� ���
  --   * �̺�Ʈ ��� Data�� ������ �������� ����
  --   * ���������� �ʿ��� ��ȸ �� ��� ���� ���� ����
  PR_CALC_BOND_INFO(T_EVENT_RESULT, T_BOND_TRADE);
  
  
  
  -- 5-1)�̺�Ʈ ��� ���
  PR_INSERT_EVENT_RESULT(T_EVENT_RESULT);
  
  -- 5-2)�ŷ����� ���
  PR_INSERT_BOND_TRADE(T_BOND_TRADE);
  
  -- 5-3)�ܰ� ���
  PR_INSERT_BOND_BALANCE(T_BOND_TRADE, T_BOND_BALANCE);
  
  
END;