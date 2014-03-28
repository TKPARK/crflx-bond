package com.test.model;

public class BondInfo {
	public String bondCd;		// 종목코드
	public String faceAmt = "0";// 액면금액
	public int bondType;		// 금리유형(1.할인채, 2.이표채(단리), 3.단리채(만기), 4.복리채)
	public String issueDate;	// 발행일자
	public String expireDate;	// 만기일자
	public String ir = "0";		// 액면이자율
	public int intCycle;		// 이자지급주기
}
