CREATE OR REPLACE PROCEDURE ISS.PR_INIT_BOND_DAMAGE (
  I_BOND_DAMAGE IN OUT BOND_DAMAGE%ROWTYPE
) IS
BEGIN
  I_BOND_DAMAGE.DAMAGE_DT           := ''; -- 손상일자(PK)
  I_BOND_DAMAGE.DAMAGE_SEQ          := 0;  -- 손상일련번호(PK)
  I_BOND_DAMAGE.FUND_CODE           := ''; -- 펀드코드
  I_BOND_DAMAGE.BOND_CODE           := ''; -- 종목코드
  I_BOND_DAMAGE.BUY_DATE            := ''; -- 매수일자
  I_BOND_DAMAGE.BUY_PRICE           := 0;  -- 매수단가
  I_BOND_DAMAGE.BALAN_SEQ           := 0;  -- 잔고일련번호
  I_BOND_DAMAGE.EVENT_DATE          := ''; -- 이벤트일
  I_BOND_DAMAGE.EVENT_SEQ           := 0;  -- 이벤트 SEQ
  I_BOND_DAMAGE.CANCEL_YN           := ''; -- 취소여부(Y/N)
  I_BOND_DAMAGE.DAMAGE_TYPE         := ''; -- 손상구분(1.손상, 2.추가손상, 3. 환입, 4.취소)
  I_BOND_DAMAGE.DAMAGE_PRICE        := 0;  -- 손상단가
  I_BOND_DAMAGE.DAMAGE_QTY          := 0;  -- 손상수량
  I_BOND_DAMAGE.DAMAGE_EVAL_AMT     := 0;  -- 손상평가금액
  I_BOND_DAMAGE.CHBF_BOOK_AMT       := 0;  -- 변경전 장부금액
  I_BOND_DAMAGE.CHBF_BOOK_PRC_AMT   := 0;  -- 변경전 장부원가
  I_BOND_DAMAGE.CHAF_BOOK_AMT       := 0;  -- 변경후 장부금액
  I_BOND_DAMAGE.CHAF_BOOK_PRC_AMT   := 0;  -- 변경후 장부원가
  I_BOND_DAMAGE.ACCRUED_INT         := 0;  -- 경과이자
  I_BOND_DAMAGE.BTRM_UNPAID_INT     := 0;  -- 전기미수이자
  I_BOND_DAMAGE.TTRM_UNPAID_INT     := 0;  -- 당기미수이자
  I_BOND_DAMAGE.DSCT_SANGGAK_AMT    := 0;  -- 할인상각금액
  I_BOND_DAMAGE.EX_CHA_SANGGAK_AMT  := 0;  -- 할증상각금액
  I_BOND_DAMAGE.CHBF_BTRM_EVAL_PRFT := 0;  -- 변경전 전기평가이익
  I_BOND_DAMAGE.CHBF_BTRM_EVAL_LOSS := 0;  -- 변경전 전기평가손실
  I_BOND_DAMAGE.REDUCTION_AM        := 0;  -- 감액금액
  
END;