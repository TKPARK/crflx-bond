CREATE OR REPLACE FUNCTION ISS.FN_INIT_BOND_BALANCE
  RETURN BOND_BALANCE%ROWTYPE AS
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;
BEGIN
  T_BOND_BALANCE.BIZ_DATE        := ''; -- 영업일자
  T_BOND_BALANCE.FUND_CODE       := ''; -- 펀드코드
  T_BOND_BALANCE.BOND_CODE       := ''; -- 종목코드
  T_BOND_BALANCE.BUY_DATE        := ''; -- 매수일자
  T_BOND_BALANCE.BUY_PRICE       := 0;  -- 매수단가
  T_BOND_BALANCE.BALAN_SEQ       := 0;  -- 잔고일련번호
  T_BOND_BALANCE.BOND_IR         := 0;  -- IR
  T_BOND_BALANCE.BOND_EIR        := 0;  -- EIR
  T_BOND_BALANCE.TOT_QTY         := 0;  -- 총잔고수량
  T_BOND_BALANCE.TDY_AVAL_QTY    := 0;  -- 당일가용수량
  T_BOND_BALANCE.NDY_AVAL_QTY    := 0;  -- 익일가용수량
  T_BOND_BALANCE.BOOK_AMT        := 0;  -- 장부금액
  T_BOND_BALANCE.BOOK_PRC_AMT    := 0;  -- 장부원가
  T_BOND_BALANCE.ACCRUED_INT     := 0;  -- 경과이자
  T_BOND_BALANCE.BTRM_UNPAID_INT := 0;  -- 전기미수이자
  T_BOND_BALANCE.TTRM_BOND_INT   := 0;  -- 당기채권이자
  T_BOND_BALANCE.SANGGAK_AMT     := 0;  -- 상각금액(상각이자)
  T_BOND_BALANCE.MI_SANGGAK_AMT  := 0;  -- 미상각금액(미상각이자)
  T_BOND_BALANCE.TRD_PRFT        := 0;  -- 매매이익
  T_BOND_BALANCE.TRD_LOSS        := 0;  -- 매매손실
  T_BOND_BALANCE.BTRM_EVAL_PRFT  := 0;  -- 전기평가이익
  T_BOND_BALANCE.BTRM_EVAL_LOSS  := 0;  -- 전기평가손실
  T_BOND_BALANCE.EVAL_PRICE      := 0;  -- 평가단가
  T_BOND_BALANCE.EVAL_AMT        := 0;  -- 평가금액
  T_BOND_BALANCE.TOT_EVAL_PRFT   := 0;  -- 누적평가이익
  T_BOND_BALANCE.TOT_EVAL_LOSS   := 0;  -- 누적평가손실
  T_BOND_BALANCE.TTRM_EVAL_PRFT  := 0;  -- 당기평가이익
  T_BOND_BALANCE.TTRM_EVAL_LOSS  := 0;  -- 당기평가손실
  T_BOND_BALANCE.AQST_QTY        := 0;  -- 인수수량
  T_BOND_BALANCE.DRT_SELL_QTY    := 0;  -- 직매도수량
  T_BOND_BALANCE.DRT_BUY_QTY     := 0;  -- 직매수수량
  T_BOND_BALANCE.TXSTD_AMT       := 0;  -- 과표금액
  T_BOND_BALANCE.CORP_TAX        := 0;  -- 선급법인세
  T_BOND_BALANCE.UNPAID_CORP_TAX := 0;  -- 미지급법인세
  
  RETURN T_BOND_BALANCE;
END;