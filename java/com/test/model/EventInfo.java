package com.test.model;

import java.util.ArrayList;

public class EventInfo {
	public String eventDate;				// 취득일
	public String evetAmt;					// 취득금액
	public ArrayList<CashFlowInfo> cfList;	// CashFlow List
	public String eir;						// EIR
	public ArrayList<DprcInfo> dpList;		// 상각 List
}
