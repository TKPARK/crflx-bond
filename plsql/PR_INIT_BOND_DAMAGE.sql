CREATE OR REPLACE PROCEDURE ISS.PR_INIT_BOND_DAMAGE (
  I_BOND_DAMAGE IN OUT BOND_DAMAGE%ROWTYPE
) IS
BEGIN
  I_BOND_DAMAGE.DAMAGE_DT            :=   '';  -- �ջ�����(PK)
  I_BOND_DAMAGE.DAMAGE_SEQ           :=    0; -- �ջ��Ϸù�ȣ(PK)
  I_BOND_DAMAGE.FUND_CODE            :=   '';  -- �ݵ��ڵ�
  I_BOND_DAMAGE.BOND_CODE            :=   '';  -- �����ڵ�
  I_BOND_DAMAGE.BUY_DATE             :=   '';  -- �ż�����
  I_BOND_DAMAGE.BUY_PRICE            :=   0;  -- �ż��ܰ�        
  I_BOND_DAMAGE.BALAN_SEQ            :=   0;  -- �ܰ��Ϸù�ȣ    
  I_BOND_DAMAGE.DAMAGE_PRICE         :=   0;  -- �ջ�ܰ�        
  I_BOND_DAMAGE.DAMAGE_QTY           :=   0;  -- �ջ����        
  I_BOND_DAMAGE.DAMAGE_EVAL_AMT      :=   0;  -- �ջ��򰡱ݾ�    
  I_BOND_DAMAGE.BOOK_AMT             :=   0;  -- ��αݾ�        
  I_BOND_DAMAGE.BOOK_PRC_AMT         :=   0;  -- ��ο���        
  I_BOND_DAMAGE.ACCRUED_INT          :=   0;  -- �������        
  I_BOND_DAMAGE.BTRM_UNPAID_INT      :=   0;  -- ����̼�����    
  I_BOND_DAMAGE.TTRM_BOND_INT        :=   0;  -- ���ä������    
  I_BOND_DAMAGE.DSCT_SANGGAK_AMT     :=   0;  -- ���λ󰢱ݾ�    
  I_BOND_DAMAGE.EX_CHA_SANGGAK_AMT   :=   0;  -- �����󰢱ݾ�    
  I_BOND_DAMAGE.REDUCTION_AM         :=   0;  -- ���ױݾ�        
  
END;