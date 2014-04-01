CREATE OR REPLACE FUNCTION ISS.FN_INIT_BOND_BALANCE
  RETURN BOND_BALANCE%ROWTYPE AS
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;
BEGIN
    T_BOND_BALANCE.BIZ_DATE        := ''; -- ��������
    T_BOND_BALANCE.FUND_CODE       := ''; -- �ݵ��ڵ�
    T_BOND_BALANCE.BOND_CODE       := ''; -- �����ڵ�
    T_BOND_BALANCE.BUY_DATE        := ''; -- �ż�����
    T_BOND_BALANCE.BUY_PRICE       :=  0; -- �ż��ܰ�
    T_BOND_BALANCE.BALAN_SEQ       :=  0; -- �ܰ��Ϸù�ȣ
    T_BOND_BALANCE.BOND_IR         :=  0; -- IR
    T_BOND_BALANCE.BOND_EIR        :=  0; -- EIR
    T_BOND_BALANCE.TOT_QTY         :=  0; -- ���ܰ����            
    T_BOND_BALANCE.TDY_AVAL_QTY    :=  0; -- ���ϰ������          
    T_BOND_BALANCE.NDY_AVAL_QTY    :=  0; -- ���ϰ������          
    T_BOND_BALANCE.BOOK_AMT        :=  0; -- ��αݾ�              
    T_BOND_BALANCE.BOOK_PRC_AMT    :=  0; -- ��ο���              
    T_BOND_BALANCE.ACCRUED_INT     :=  0; -- �������              
    T_BOND_BALANCE.BTRM_UNPAID_INT :=  0; -- ����̼�����          
    T_BOND_BALANCE.TTRM_BOND_INT   :=  0; -- ���ä������          
    T_BOND_BALANCE.SANGGAK_AMT     :=  0; -- �󰢱ݾ�(������)    
    T_BOND_BALANCE.MI_SANGGAK_AMT  :=  0; -- �̻󰢱ݾ�(�̻�����)
    T_BOND_BALANCE.TRD_PRFT        :=  0; -- �Ÿ�����              
    T_BOND_BALANCE.TRD_LOSS        :=  0; -- �Ÿżս�              
    T_BOND_BALANCE.BTRM_EVAL_PRFT  :=  0; -- ����������          
    T_BOND_BALANCE.BTRM_EVAL_LOSS  :=  0; -- �����򰡼ս�          
    T_BOND_BALANCE.EVAL_PRICE      :=  0; -- �򰡴ܰ�              
    T_BOND_BALANCE.EVAL_AMT        :=  0; -- �򰡱ݾ�              
    T_BOND_BALANCE.TOT_EVAL_PRFT   :=  0; -- ����������          
    T_BOND_BALANCE.TOT_EVAL_LOSS   :=  0; -- �����򰡼ս�          
    T_BOND_BALANCE.TTRM_EVAL_PRFT  :=  0; -- ���������          
    T_BOND_BALANCE.TTRM_EVAL_LOSS  :=  0; -- ����򰡼ս�          
    T_BOND_BALANCE.AQST_QTY        :=  0; -- �μ�����              
    T_BOND_BALANCE.DRT_SELL_QTY    :=  0; -- ���ŵ�����            
    T_BOND_BALANCE.DRT_BUY_QTY     :=  0; -- ���ż�����            
    T_BOND_BALANCE.TXSTD_AMT       :=  0; -- ��ǥ�ݾ�              
    T_BOND_BALANCE.CORP_TAX        :=  0; -- ���޹��μ�            
    T_BOND_BALANCE.UNPAID_CORP_TAX :=  0; -- �����޹��μ�    
    
    RETURN T_BOND_BALANCE;
END;