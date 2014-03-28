package com.test.model;

public class CashFlowInfo {
	public String cfIssueDate;			// 현금흐름발생일
	public int intDays = 0;				// 이자일수
	public int addDays = 0;				// 누적일수
	public String intCashFlowAmt = "0";	// 이자CF금액
	public String priCashFlowAmt = "0";	// 원금CF금액
	public String totalAmt = "0";		// 금액(합계)
	public String cv = "0";				// 현재가치
	
	@Override
	public String toString() {
		return "CashFlowInfo [cfIssueDate=" + cfIssueDate
				+ ", intDays=" + intDays + ", addDays=" + addDays
				+ ", intCashFlowAmt=" + intCashFlowAmt + ", priCashFlowAmt="
				+ priCashFlowAmt + ", totalAmt=" + totalAmt + ", cv=" + cv
				+ "]";
	}
}
