------------------------------------------------------------------------------
--  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
--  All rights reserved.
--  Authors: Oliver Bruendler
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Description
------------------------------------------------------------------------------
-- This entity implements a full AXI master. In contrast to psi_common_axi_master_full,
-- this entity can do unaligned transfers and it supports different width for the 
-- AXI interface than for the data interface. The AXI interface can be wider than
-- the data interface but not vice versa.
-- The flexibility of doing unaligned transfers is paid by lower performance for
-- very small transfers. There is an overhead of some clock cycles per command.

------------------------------------------------------------------------------
-- Libraries
------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.numeric_std.all;
	
library work;
	use work.psi_common_math_pkg.all;
	use work.psi_common_logic_pkg.all;

------------------------------------------------------------------------------
-- Entity
------------------------------------------------------------------------------	
-- $$ testcases=simple_tf,axi_hs,user_hs,all_shifts$$
-- $$ processes=user_cmd,user_data,user_resp,axi $$
-- $$ tbpkg=work.psi_tb_txt_util,work.psi_tb_compare_pkg,work.psi_tb_activity_pkg $$
entity psi_common_axi_master_full is
	generic 
	(
		AxiAddrWidth_g				: natural range 12 to 64	:= 32;			-- $$ constant=32 $$
		AxiDataWidth_g				: natural range 8 to 1024	:= 32;			-- $$ export=true $$
		AxiMaxBeats_g				: natural range 1 to 256	:= 256;			-- $$ constant=16 $$
		AxiMaxOpenTrasactions_g		: natural range 1 to 8		:= 8;			-- $$ constant=3 $$
		UserTransactionSizeBits_g	: natural					:= 32;			-- $$ constant=10 $$
		DataFifoDepth_g				: natural					:= 1024;		-- $$ constant=10 $$
		DataWidth_g					: natural					:= 32;			-- $$ constant=16 $$
		ImplRead_g					: boolean					:= true;		-- $$ export=true $$
		ImplWrite_g					: boolean					:= true;		-- $$ export=true $$
		RamBehavior_g				: string					:= "RBW"		-- $$ constant="RBW" $$
	);
	port
	(
		-- Control Signals
		M_Axi_Aclk		: in 	std_logic;													-- $$ type=clk; freq=100e6; proc=user_cmd,user_data,user_resp,axi $$
		M_Axi_Aresetn	: in 	std_logic;													-- $$ type=rst; clk=M_Axi_Aclk; lowactive=true $$
		
		-- User Command Interface
		CmdWr_Addr		: in	std_logic_vector(AxiAddrWidth_g-1 downto 0)				:= (others => '0');		-- $$ proc=user_cmd $$
		CmdWr_Size		: in	std_logic_vector(UserTransactionSizeBits_g-1 downto 0)	:= (others => '0');  	-- $$ proc=user_cmd $$
		CmdWr_LowLat	: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdWr_Vld		: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdWr_Rdy		: out	std_logic;																		-- $$ proc=user_cmd $$
		
		-- User Command Interface
		CmdRd_Addr		: in	std_logic_vector(AxiAddrWidth_g-1 downto 0)				:= (others => '0');		-- $$ proc=user_cmd $$
		CmdRd_Size		: in	std_logic_vector(UserTransactionSizeBits_g-1 downto 0)	:= (others => '0');  	-- $$ proc=user_cmd $$
		CmdRd_LowLat	: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdRd_Vld		: in	std_logic												:= '0';					-- $$ proc=user_cmd $$
		CmdRd_Rdy		: out	std_logic;																		-- $$ proc=user_cmd $$		
		
		-- Write Data
		WrDat_Data		: in	std_logic_vector(DataWidth_g-1 downto 0)				:= (others => '0');		-- $$ proc=user_data $$
		WrDat_Vld		: in	std_logic												:= '0';					-- $$ proc=user_data $$
		WrDat_Rdy		: out	std_logic;																		-- $$ proc=user_data $$		
    
		-- Read Data
		RdDat_Data		: out	std_logic_vector(DataWidth_g-1 downto 0);										-- $$ proc=user_data $$
		RdDat_Vld		: out	std_logic;																		-- $$ proc=user_data $$
		RdDat_Rdy		: in	std_logic												:= '0';					-- $$ proc=user_data $$			
		
		-- Response
		Wr_Done			: out	std_logic;																		-- $$ proc=user_resp $$
		Wr_Error		: out	std_logic;																		-- $$ proc=user_resp $$
		Rd_Done			: out	std_logic;																		-- $$ proc=user_resp $$
		Rd_Error		: out	std_logic;																		-- $$ proc=user_resp $$
		
		-- AXI Address Write Channel
		M_Axi_AwAddr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);									-- $$ proc=axi $$
		M_Axi_AwLen		: out	std_logic_vector(7 downto 0);													-- $$ proc=axi $$
		M_Axi_AwSize	: out	std_logic_vector(2 downto 0);													-- $$ proc=axi $$
		M_Axi_AwBurst	: out	std_logic_vector(1 downto 0);													-- $$ proc=axi $$
		M_Axi_AwLock	: out	std_logic;																		-- $$ proc=axi $$
		M_Axi_AwCache	: out	std_logic_vector(3 downto 0);													-- $$ proc=axi $$
		M_Axi_AwProt	: out	std_logic_vector(2 downto 0);													-- $$ proc=axi $$
		M_Axi_AwValid	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_AwReady	: in	std_logic                                             	:= '0';			     	-- $$ proc=axi $$
    
		-- AXI Write Data Channel                                                           					-- $$ proc=axi $$
		M_Axi_WData		: out	std_logic_vector(AxiDataWidth_g-1 downto 0);                					-- $$ proc=axi $$
		M_Axi_WStrb		: out	std_logic_vector(AxiDataWidth_g/8-1 downto 0);              					-- $$ proc=axi $$
		M_Axi_WLast		: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_WValid	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_WReady	: in	std_logic                                              := '0';				    -- $$ proc=axi $$
    
		-- AXI Write Response Channel                                                      
		M_Axi_BResp		: in	std_logic_vector(1 downto 0)                           := (others => '0');	    -- $$ proc=axi $$
		M_Axi_BValid	: in	std_logic                                              := '0';				    -- $$ proc=axi $$
		M_Axi_BReady	: out	std_logic;                                                  					-- $$ proc=axi $$
    
		-- AXI Read Address Channel                                               
		M_Axi_ArAddr	: out	std_logic_vector(AxiAddrWidth_g-1 downto 0);                					-- $$ proc=axi $$
		M_Axi_ArLen		: out	std_logic_vector(7 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArSize	: out	std_logic_vector(2 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArBurst	: out	std_logic_vector(1 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArLock	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_ArCache	: out	std_logic_vector(3 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArProt	: out	std_logic_vector(2 downto 0);                               					-- $$ proc=axi $$
		M_Axi_ArValid	: out	std_logic;                                                  					-- $$ proc=axi $$
		M_Axi_ArReady	: in	std_logic                                           	:= '0';					-- $$ proc=axi $$
    
		-- AXI Read Data Channel                                                      
		M_Axi_RData		: in	std_logic_vector(AxiDataWidth_g-1 downto 0)             := (others => '0');    	-- $$ proc=axi $$
		M_Axi_RResp		: in	std_logic_vector(1 downto 0)                            := (others => '0');	    -- $$ proc=axi $$
		M_Axi_RLast		: in	std_logic                                               := '0';				    -- $$ proc=axi $$
		M_Axi_RValid	: in	std_logic                                               := '0';				    -- $$ proc=axi $$
		M_Axi_RReady	: out	std_logic		                                         						-- $$ proc=axi $$
	);	
end entity;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture rtl of psi_common_axi_master_full is 

	------------------------------------------------------------------------------
	-- Constants
	------------------------------------------------------------------------------	
	constant AxiBytes_c		: natural 	:= AxiDataWidth_g/8;
	constant DataBytes_c	: natural	:= DataWidth_g/8;
	constant WidthRatio_c	: natural	:= AxiDataWidth_g/DataWidth_g;
	
	
	------------------------------------------------------------------------------
	-- Type
	------------------------------------------------------------------------------	
	type WriteCmdFsm_t is (Idle_s, Apply_s);
	type WriteWconvFsm_t is (Idle_s, Transfer_s);
	type WriteAlignFsm_t is (Idle_s, Transfer_s, Last_s);
	type ReadCmdFsm_t is (Idle_s, Apply_s, WaitDataFsm_s);
	type ReadDataFsm_t is (Idle_s, Transfer_s, Wait_s);
	
	
	------------------------------------------------------------------------------
	-- Functions
	------------------------------------------------------------------------------	
	function AlignedAddr_f(	Addr 	: in unsigned(AxiAddrWidth_g-1 downto 0)) 
							return unsigned is
		variable Addr_v : unsigned(Addr'range) := (others => '0');
	begin
		Addr_v(Addr'left downto log2(AxiBytes_c)) := Addr(Addr'left downto log2(AxiBytes_c));
		return Addr_v;		
	end function;
	
	------------------------------------------------------------------------------
	-- Two Process Record
	------------------------------------------------------------------------------		
	type two_process_r is record
	
		-- *** Write Related Registers ***
		WrCmdFsm		: WriteCmdFsm_t;
		WrLastAddr		: unsigned(AxiAddrWidth_g-1 downto 0);
		CmdWr_Rdy		: std_logic;
		AxiWrCmd_Addr	: std_logic_vector(AxiAddrWidth_g-1 downto 0);
		AxiWrCmd_Size	: std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
		WrAlignCmdSize	: std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
		AxiWrCmd_LowLat	: std_logic;
		AxiWrCmd_Vld	: std_logic;
		WrWconvFsm		: WriteWconvFsm_t;
		WrStartTf		: std_logic;
		WrWordsDone		: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrDataWordsCmd	: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrDataWordsWc	: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrAlignFsm		: WriteAlignFsm_t;
		WrAlignReg		: std_logic_vector(AxiDataWidth_g*2-1 downto 0);
		WrAlignBe		: std_logic_vector(AxiBytes_c*2-1 downto 0);		
		WrShift			: unsigned(log2(AxiBytes_c)-1 downto 0);
		WrAlignShift	: unsigned(log2(AxiBytes_c)-1 downto 0);
		WrAlignVld		: std_logic;
		AxiWordCnt		: unsigned(UserTransactionSizeBits_g-1 downto 0);
		WrLastBe		: std_logic_vector(AxiBytes_c-1 downto 0);
		WrAlignLastBe	: std_logic_vector(AxiBytes_c-1 downto 0);
		WrAlignLast		: std_logic;
		
		-- *** Read Related Registers *** 
		RdCmdFsm		: ReadCmdFsm_t;
		RdLastAddr		: unsigned(AxiAddrWidth_g-1 downto 0);
		RdFirstAddrOffs	: unsigned(log2(AxiBytes_c)-1 downto 0);
		CmdRd_Rdy		: std_logic;
		AxiRdCmd_Addr	: std_logic_vector(AxiAddrWidth_g-1 downto 0);
		AxiRdCmd_LowLat	: std_logic;
		AxiRdCmd_Vld	: std_logic;
		AxiRdCmd_Size	: std_logic_vector(UserTransactionSizeBits_g-1 downto 0);
		RdFirstBe		: std_logic_vector(AxiBytes_c-1 downto 0);
		RdLastBe		: std_logic_vector(AxiBytes_c-1 downto 0);
		RdDataFsm		: ReadDataFsm_t;
		RdStartTf		: std_logic;
		RdDataEna		: std_logic;
		RdDatFirstBe	: std_logic_vector(AxiBytes_c-1 downto 0);
		RdDatLastBe		: std_logic_vector(AxiBytes_c-1 downto 0);
		RdDataWords		: unsigned(UserTransactionSizeBits_g-1 downto 0);
		RdCurrentWord	: unsigned(UserTransactionSizeBits_g-1 downto 0);
		RdShift			: unsigned(log2(AxiBytes_c)-1 downto 0);
		RdLowIdx		: unsigned(log2(AxiBytes_c) downto 0);
		RdAlignShift	: unsigned(log2(AxiBytes_c)-1 downto 0);	
		RdAlignLowIdx	: unsigned(log2(AxiBytes_c) downto 0);	
		RdAlignByteVld	: std_logic_vector(AxiBytes_c*2-1 downto 0);
		RdAlignReg		: std_logic_vector(AxiDataWidth_g*2-1 downto 0);
		RdAlignLast		: std_logic;
	end record;
	signal r, r_next : two_process_r;
		
	
	------------------------------------------------------------------------------
	-- Instantiation Signals
	------------------------------------------------------------------------------
	signal Rst				: std_logic;
	signal WrFifo_Data		: std_logic_vector(WrDat_Data'range);
	signal WrFifo_Vld		: std_logic;
	signal AxiWrCmd_Rdy		: std_logic;
	signal AxiWrDat_Rdy		: std_logic;
	signal AxiWrDat_Data	: std_logic_vector(AxiDataWidth_g-1 downto 0);
	signal WrFifo_Rdy		: std_logic;
	signal AxiWrDat_Be		: std_logic_vector(AxiBytes_c-1 downto 0);	
	signal WrWconvEna		: std_logic;
	signal WrWconv_Vld		: std_logic;
	signal WrWconv_Rdy		: std_logic;
	signal WrWconv_Last		: std_logic;
	signal WrData_Vld		: std_logic;
	signal WrData_Data		: std_logic_vector(AxiDataWidth_g-1 downto 0);
	signal WrData_Last		: std_logic;
	signal WrData_We		: std_logic_vector(AxiBytes_c/DataBytes_c-1 downto 0);
	signal WrData_Rdy		: std_logic;
	signal WrDataEna		: std_logic;
	signal AxiRdCmd_Rdy		: std_logic;	
	signal AxiRdDat_Rdy		: std_logic;
	signal AxiRdDat_Vld		: std_logic;
	signal AxiRdDat_Data	: std_logic_vector(AxiDataWidth_g-1 downto 0);
	signal RdFifo_Rdy		: std_logic;
	signal RdFifo_Data		: std_logic_vector(DataWidth_g-1 downto 0);
	signal RdFifo_Vld		: std_logic;
	
begin
	
	------------------------------------------------------------------------------
	-- Assertions
	------------------------------------------------------------------------------
	assert AxiDataWidth_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_full AxiDataWidth_g must be a multiple of 8" severity failure;
	assert DataWidth_g mod 8 = 0 report "###ERROR###: psi_common_axi_master_full DataWidth_g must be a multiple of 8" severity failure;
	assert AxiDataWidth_g mod DataWidth_g = 0 report "###ERROR###: psi_common_axi_master_full AxiDataWidth_g must be a multiple of DataWidth_g" severity failure;
	
	
	------------------------------------------------------------------------------
	-- Combinatorial Process
	------------------------------------------------------------------------------	
	p_comb : process(	r,
						CmdWr_Addr, CmdWr_Size, CmdWr_Vld, CmdWr_LowLat,
						CmdRd_Addr, CmdRd_Size, CmdRd_Vld, CmdRd_LowLat,
						AxiWrCmd_Rdy, AxiWrDat_Rdy,
						AxiRdCmd_Rdy, AxiRdDat_Vld, AxiRdDat_Data,
						WrWconv_Rdy, WrFifo_Vld,
						WrData_Vld, WrData_Data, WrData_Last, WrData_We,
						RdFifo_Rdy)
		variable v 					: two_process_r;
		variable WriteBe_v			: std_logic_vector(AxiBytes_c-1 downto 0);
		variable RdAlignReady_v		: std_logic;
		variable RdLowIdxInt_v		: integer range 0 to AxiBytes_c;
		variable RdDatBe_v			: std_logic_vector(AxiBytes_c-1 downto 0);
		variable RdDataLast_v		: std_logic;
	begin
		-- *** Keep two process variables stable ***
		v := r;
		
		--------------------------------------------------------------------------
		-- Write Related Code
		--------------------------------------------------------------------------	
		if ImplWrite_g then
		
			-- *** Command FSM ***
			v.WrStartTf	:= '0';
			v.AxiWrCmd_Vld	:= '0';
			case r.WrCmdFsm is
			
				when Idle_s =>
					v.CmdWr_Rdy			:= '1';
					v.WrLastAddr		:= unsigned(CmdWr_Addr) + unsigned(CmdWr_Size) - 1;
					if unsigned(CmdWr_Size(log2(DataBytes_c)-1 downto 0)) = 0 then
						v.WrDataWordsCmd	:= resize(unsigned(CmdWr_Size(CmdWr_Size'high downto log2(DataBytes_c))), UserTransactionSizeBits_g);
					else
						v.WrDataWordsCmd	:= resize(unsigned(CmdWr_Size(CmdWr_Size'high downto log2(DataBytes_c)))+1, UserTransactionSizeBits_g);
					end if;
					v.AxiWrCmd_Addr		:= std_logic_vector(AlignedAddr_f(unsigned(CmdWr_Addr)));
					v.WrShift			:= unsigned(CmdWr_Addr(v.WrShift'range));
					v.AxiWrCmd_LowLat	:= CmdWr_LowLat;
					if CmdWr_Vld = '1' then
						v.CmdWr_Rdy		:= '0';
						v.WrCmdFsm		:= Apply_s;						
					end if;
					
				when Apply_s =>			
					if (AxiWrCmd_Rdy = '1') and (r.WrWconvFsm = Idle_s) and (r.WrAlignFsm = Idle_s) then
						v.AxiWrCmd_Vld	:= '1';
						v.WrStartTf	:= '1';
						v.WrCmdFsm		:= Idle_s;
						v.CmdWr_Rdy		:= '1';						
						v.AxiWrCmd_Size	:= std_logic_vector(resize(shift_right(AlignedAddr_f(r.WrLastAddr) - unsigned(r.AxiWrCmd_Addr), log2(AxiBytes_c))+1, UserTransactionSizeBits_g));
						-- Calculate byte enables for last word
						for byte in 0 to AxiBytes_c-1 loop
							if r.WrLastAddr(log2(AxiBytes_c)-1 downto 0) >= byte then
								v.WrLastBe(byte)	:= '1';
							else	
								v.WrLastBe(byte)	:= '0';
							end if;
						end loop;
					end if;					
				
				when others => null;
			
			end case;
			
			-- *** With Conversion FSM ***
			WrWconvEna	<= '0';
			WrWconv_Last <= '0';
			case r.WrWconvFsm is 
			
				-- Latch values that change for the next command that may be interpreted while the current one is running
				when Idle_s =>
					v.WrWordsDone		:= to_unsigned(1, v.WrWordsDone'length);
					v.WrDataWordsWc	:= r.WrDataWordsCmd;
					if r.WrStartTf = '1' then
						v.WrWconvFsm 	:= Transfer_s;	
					end if;
							
				-- Execute transfer
				when Transfer_s =>
					WrWconvEna <= '1';
					if r.WrWordsDone = r.WrDataWordsWc then
						WrWconv_Last	<= '1';
					end if;		
					if (WrWconv_Rdy = '1') and (WrFifo_Vld = '1') then
						v.WrWordsDone := r.WrWordsDone + 1;
						if r.WrWordsDone = r.WrDataWordsWc then
							v.WrWconvFsm 	:= Idle_s;	
						end if;
					end if;
				
				when others => null;				
			end case;
			
			-- *** Alignment FSM ***
			-- Initial values
			WrDataEna <= '0';
			--v.WrAlignVld := '0';
			-- Word- to Byte-Enable conversion
			for i in 0 to AxiBytes_c-1 loop
				WriteBe_v(i)	:= WrData_We(i/DataWidth_g);
			end loop;
			-- FSM
			case r.WrAlignFsm is
			
				-- Latch values that change for the next command that may be interpreted while the current one is running
				when Idle_s =>				
					v.WrAlignReg 		:= (others => '0');
					v.WrAlignBe			:= (others => '0');
					v.AxiWordCnt		:= to_unsigned(1, v.AxiWordCnt'length);
					v.WrAlignLast		:= '0';
					v.WrAlignShift		:= r.WrShift;
					v.WrAlignCmdSize	:= r.AxiWrCmd_Size;
					v.WrAlignLastBe		:= r.WrLastBe;
					v.WrAlignVld 		:= '0';
					if r.WrStartTf = '1' then
						v.WrAlignFsm := Transfer_s;
					end if;
					
				-- Move data from the FIFO to AXI
				when Transfer_s =>
					WrDataEna <= '1';
					if (AxiWrDat_Rdy = '1') and ((WrData_Vld = '1') or (r.WrAlignLast = '1')) then			
						-- Don't add new byte enables on last data flushing
						if r.WrAlignLast = '1' then
							WriteBe_v := (others => '0');
						end if;
						-- Shift
						v.WrAlignReg(AxiDataWidth_g-1 downto 0)	:= r.WrAlignReg(r.WrAlignReg'left downto AxiDataWidth_g);
						v.WrAlignBe(AxiBytes_c-1 downto 0)		:= r.WrAlignBe(r.WrAlignBe'left downto AxiBytes_c);					
						-- New Data
						v.WrAlignReg((to_integer(r.WrAlignShift)+AxiBytes_c)*8-1 downto to_integer(r.WrAlignShift)*8) := WrData_Data;
						v.WrAlignBe(to_integer(r.WrAlignShift)+AxiBytes_c-1 downto to_integer(r.WrAlignShift)) := WriteBe_v;
						-- Flow control
						v.WrAlignVld	:= '1';
						if r.AxiWordCnt = unsigned(r.WrAlignCmdSize) then
							v.WrAlignFsm := Last_s;
							v.WrAlignBe(AxiBytes_c-1 downto 0) := v.WrAlignBe(AxiBytes_c-1 downto 0) and r.WrAlignLastBe;
						end if;	
						v.AxiWordCnt := r.AxiWordCnt+1;
						-- Force last data out
						v.WrAlignLast := WrData_Last;	
					elsif AxiWrDat_Rdy = '1' then
						v.WrAlignVld	:= '0';
					end if;
				
				-- Wait for the last beat te be accepted without reading more data from the FIFO
				when Last_s =>
					v.WrAlignVld	:= '1';
					if AxiWrDat_Rdy = '1' then
						v.WrAlignVld	:= '0';
						v.WrAlignFsm := Idle_s;
					end if;				
					
				when others => null;	
			end case;
		end if;
		
		--------------------------------------------------------------------------
		-- Read Related Code
		--------------------------------------------------------------------------	
		if ImplRead_g then
		
			-- *** Variables ***
			RdLowIdxInt_v := to_integer(r.RdAlignLowIdx);
			RdAlignReady_v := r.RdDataEna;
			-- Vivado workaround
			for i in 0 to AxiBytes_c loop
			    if i = RdLowIdxInt_v then
					-- no new data fits into shifter, even if output is ready. This only happens for user width < axi width
                    if (DataBytes_c < AxiBytes_c) and (unsigned(r.RdAlignByteVld(r.RdAlignByteVld'high downto i+DataBytes_c)) /= 0) then
                        RdAlignReady_v := '0';		
					-- if output is ready, new data can be accepted (back-to-back)
                    elsif unsigned(r.RdAlignByteVld(r.RdAlignByteVld'high downto i)) /= 0 and RdFifo_Rdy = '0' then
                        RdAlignReady_v := '0';
                    end if;
                 end if;
             end loop;
			
			-- *** Command FSM ***
			v.RdStartTf	:= '0';
			v.AxiRdCmd_Vld	:= '0';			
			case r.RdCmdFsm is 

				when Idle_s =>
				
					v.CmdRd_Rdy			:= '1';
					v.RdLastAddr		:= unsigned(CmdRd_Addr) + unsigned(CmdRd_Size) - 1;
					v.RdFirstAddrOffs	:= unsigned(CmdRd_Addr(v.RdFirstAddrOffs'range));
					v.AxiRdCmd_Addr		:= std_logic_vector(AlignedAddr_f(unsigned(CmdRd_Addr)));
					v.AxiRdCmd_LowLat	:= CmdRd_LowLat;
					v.RdShift			:= unsigned(CmdRd_Addr(v.RdShift'range));
					v.RdLowIdx			:= to_unsigned(AxiBytes_c, v.RdLowIdx'length) - unsigned(CmdRd_Addr(v.RdShift'range));
					if CmdRd_Vld = '1' then
						v.CmdRd_Rdy		:= '0';
						v.RdCmdFsm		:= Apply_s;						
					end if;
					
				when Apply_s =>		
					-- AXI command can be sent early
					if (AxiRdCmd_Rdy = '1') then
						v.AxiRdCmd_Vld	:= '1';
						v.RdCmdFsm		:= WaitDataFsm_s;		
						v.RdStartTf	:= '1';
						v.AxiRdCmd_Size	:= std_logic_vector(resize(shift_right(AlignedAddr_f(r.RdLastAddr) - unsigned(r.AxiRdCmd_Addr), log2(AxiBytes_c))+1, UserTransactionSizeBits_g));
						-- Calculate byte enables for last byte
						for byte in 0 to AxiBytes_c-1 loop
							if r.RdLastAddr(log2(AxiBytes_c)-1 downto 0) >= byte then
								v.RdLastBe(byte) := '1';
							else
								v.RdLastBe(byte) := '0';
							end if;
						end loop;
						-- Calculate byte enables for first byte
						for byte in 0 to AxiBytes_c-1 loop
							if r.RdFirstAddrOffs <= byte then
								v.RdFirstBe(byte) := '1';
							else
								v.RdFirstBe(byte) := '0';
							end if;
						end loop;						
					end if;
					
				-- Start data FSM before sending next command to avoid owerwriting data before it was latched
				when WaitDataFsm_s =>
					v.RdStartTf	:= '1';
					if r.RdDataFsm = Idle_s then
						v.RdCmdFsm 	:= Idle_s;
						v.CmdRd_Rdy	:= '1';	
						v.RdStartTf	:= '0';
					end if;
				
				
				when others => null;
			end case;
			
			-- *** Data FSM ***
			v.RdDataEna	:= '0';
			RdDatBe_v := (others => '1');
			RdDataLast_v := '0';
			case r.RdDataFsm is
				
				when Idle_s =>					
					v.RdDatFirstBe	:= r.RdFirstBe;
					v.RdDatLastBe	:= r.RdLastBe;
					v.RdDataWords	:= unsigned(r.AxiRdCmd_Size);
					v.RdCurrentWord	:= to_unsigned(1, v.RdCurrentWord'length);
					v.RdAlignShift	:= r.RdShift;
					v.RdAlignLowIdx	:= r.RdLowIdx;
					if r.RdStartTf = '1' then
						v.RdDataFsm 	:= Transfer_s;
						v.RdDataEna 	:= '1';
					end if;
				
				when Transfer_s =>
					v.RdDataEna 	:= '1';
					if r.RdCurrentWord = 1 then
						RdDatBe_v 		:= RdDatBe_v and r.RdDatFirstBe;
					end if;
					if r.RdCurrentWord = r.RdDataWords then
						RdDatBe_v		:= RdDatBe_v and r.RdDatLastBe;
						RdDataLast_v	:= '1';
					end if;
					if (RdAlignReady_v = '1') and (AxiRdDat_Vld = '1') and (r.RdDataEna = '1') then
						v.RdCurrentWord := r.RdCurrentWord + 1;
						if r.RdCurrentWord = r.RdDataWords then
							v.RdDataEna 	:= '0';
							v.RdDataFsm		:= Wait_s;
						end if;
					end if;
					
				-- Wait until reception of all data is done
				when Wait_s =>
					if unsigned(r.RdAlignByteVld) = 0 then	
						v.RdDataFsm		:= Idle_s;
					end if;
				
				when others => null;
			end case;
			
			-- *** Data Alignment ***
			AxiRdDat_Rdy <= RdAlignReady_v;
			RdFifo_Vld <= '0';
			-- shift
			if (RdFifo_Rdy = '1') and (RdAlignReady_v = '0' or AxiRdDat_Vld = '1' or r.RdAlignLast = '1') then
				-- Shift is only done if data can be consumed (RdFifo_Rdy) and either no new data is required for the next shift (RdAlignReady_v = '0'),
				-- .. the data is available (AxiRdDat_Vld = '1') or we are at the end of a transfer (r.RdAlignLast = '1')
				v.RdAlignReg		:= ZerosVector(DataWidth_g) & r.RdAlignReg(r.RdAlignReg'left downto DataWidth_g);
				v.RdAlignByteVld 	:= ZerosVector(DataBytes_c) & r.RdAlignByteVld(r.RdAlignByteVld'left downto DataBytes_c);
				if r.RdAlignLast = '1' then
					RdFifo_Vld <= ReduceOr(r.RdAlignByteVld(DataBytes_c-1 downto 0));
				else
					RdFifo_Vld <= ReduceAnd(r.RdAlignByteVld(DataBytes_c-1 downto 0));
				end if;
			end if;
			-- get new data
			if RdAlignReady_v = '1' and AxiRdDat_Vld = '1' then
				v.RdAlignReg(RdLowIdxInt_v*8+AxiDataWidth_g-1 downto RdLowIdxInt_v*8)	:= AxiRdDat_Data;
				v.RdAlignByteVld(RdLowIdxInt_v+AxiBytes_c-1 downto RdLowIdxInt_v)		:= RdDatBe_v;
				v.RdAlignLast	:= RdDataLast_v;
			end if;
			
			-- Send data to FIFO
			RdFifo_Data <= r.RdAlignReg(DataWidth_g-1 downto 0);

			
		end if;
		
		
		-- *** Update Signal ***
		r_next <= v;
	end process;
	
	------------------------------------------------------------------------------
	-- Registered Process
	------------------------------------------------------------------------------
	p_reg : process(M_Axi_Aclk)
	begin
		if rising_edge(M_Axi_Aclk) then
			r <= r_next;
			if M_Axi_Aresetn = '0' then
				-- *** Write Related Registers ***
				if ImplWrite_g then
					r.WrCmdFsm 		<= Idle_s;
					r.CmdWr_Rdy		<= '0';
					r.AxiWrCmd_Vld	<= '0';
					r.WrWconvFsm	<= Idle_s;
					r.WrStartTf		<= '0';
					r.WrAlignFsm	<= Idle_s;
					r.WrAlignVld	<= '0';
				end if;
				-- *** Read Related Registers ***
				if ImplRead_g then
					r.RdCmdFsm			<= Idle_s;
					r.CmdRd_Rdy			<= '0';
					r.AxiRdCmd_Vld		<= '0';
					r.RdDataFsm			<= Idle_s;
					r.RdStartTf			<= '0';
					r.RdDataEna			<= '0';
					r.RdAlignByteVld	<= (others => '0');
				end if;
			end if;
		end if;
	end process;
	
	------------------------------------------------------------------------------
	-- Outputs
	------------------------------------------------------------------------------		
	CmdWr_Rdy	<= r.CmdWr_Rdy;
	CmdRd_Rdy	<= r.CmdRd_Rdy;

	
	------------------------------------------------------------------------------
	-- Constant Outputs
	------------------------------------------------------------------------------	
	
	------------------------------------------------------------------------------
	-- Instantiations
	------------------------------------------------------------------------------
	Rst <= not M_Axi_Aresetn;
	
	-- AXI Master Interface
	AxiWrDat_Data 	<= r.WrAlignReg(AxiWrDat_Data'range);
	AxiWrDat_Be		<= r.WrAlignBe(AxiWrDat_Be'range);
	i_axi : entity work.psi_common_axi_master_simple
		generic  map
		(
			AxiAddrWidth_g				=> AxiAddrWidth_g,
			AxiDataWidth_g				=> AxiDataWidth_g,
			AxiMaxBeats_g				=> AxiMaxBeats_g,
			AxiMaxOpenTrasactions_g		=> AxiMaxOpenTrasactions_g,
			UserTransactionSizeBits_g	=> UserTransactionSizeBits_g,
			DataFifoDepth_g				=> AxiMaxBeats_g*2,
			ImplRead_g					=> ImplRead_g,
			ImplWrite_g					=> ImplWrite_g,
			RamBehavior_g				=> RamBehavior_g
		)
		port map
		(
			-- Control Signals
			M_Axi_Aclk		=> M_Axi_Aclk,
			M_Axi_Aresetn	=> M_Axi_Aresetn,
			-- User Command Interface
			CmdWr_Addr		=> r.AxiWrCmd_Addr,
			CmdWr_Size		=> r.AxiWrCmd_Size,
			CmdWr_LowLat	=> r.AxiWrCmd_LowLat,
			CmdWr_Vld		=> r.AxiWrCmd_Vld,
			CmdWr_Rdy		=> AxiWrCmd_Rdy,			
			-- User Command Interface
			CmdRd_Addr		=> r.AxiRdCmd_Addr,
			CmdRd_Size		=> r.AxiRdCmd_Size,
			CmdRd_LowLat	=> r.AxiRdCmd_LowLat,
			CmdRd_Vld		=> r.AxiRdCmd_Vld,
			CmdRd_Rdy		=> AxiRdCmd_Rdy,		
			-- Write Data
			WrDat_Data		=> AxiWrDat_Data,
			WrDat_Be		=> AxiWrDat_Be,
			WrDat_Vld		=> r.WrAlignVld,
			WrDat_Rdy		=> AxiWrDat_Rdy,
			-- Read Data
			RdDat_Data		=> AxiRdDat_Data,
			RdDat_Vld		=> AxiRdDat_Vld,
			RdDat_Rdy		=> AxiRdDat_Rdy,
			-- Response
			Wr_Done			=> Wr_Done,
			Wr_Error		=> Wr_Error,
			Rd_Done			=> Rd_Done,
			Rd_Error		=> Rd_Error,			
			-- AXI Address Write Channel
			M_Axi_AwAddr	=> M_Axi_AwAddr,
			M_Axi_AwLen		=> M_Axi_AwLen,
			M_Axi_AwSize	=> M_Axi_AwSize,
			M_Axi_AwBurst	=> M_Axi_AwBurst,
			M_Axi_AwLock	=> M_Axi_AwLock,
			M_Axi_AwCache	=> M_Axi_AwCache,
			M_Axi_AwProt	=> M_Axi_AwProt,
			M_Axi_AwValid	=> M_Axi_AwValid,
			M_Axi_AwReady	=> M_Axi_AwReady,
			-- AXI Write Data Channel
			M_Axi_WData		=> M_Axi_WData,	
			M_Axi_WStrb		=> M_Axi_WStrb,	
			M_Axi_WLast		=> M_Axi_WLast,
			M_Axi_WValid	=> M_Axi_WValid,
			M_Axi_WReady	=> M_Axi_WReady,
			-- AXI Write Response Channel                                                      
			M_Axi_BResp		=> M_Axi_BResp,	
			M_Axi_BValid	=> M_Axi_BValid,
			M_Axi_BReady	=> M_Axi_BReady,
			-- AXI Read Address Channel                                               
			M_Axi_ArAddr	=> M_Axi_ArAddr,
			M_Axi_ArLen		=> M_Axi_ArLen,	
			M_Axi_ArSize	=> M_Axi_ArSize,
			M_Axi_ArBurst	=> M_Axi_ArBurst,
			M_Axi_ArLock	=> M_Axi_ArLock,
			M_Axi_ArCache	=> M_Axi_ArCache,
			M_Axi_ArProt	=> M_Axi_ArProt,
			M_Axi_ArValid	=> M_Axi_ArValid,
			M_Axi_ArReady	=> M_Axi_ArReady,
			-- AXI Read Data Channel                                                      
			M_Axi_RData		=> M_Axi_RData,	
			M_Axi_RResp		=> M_Axi_RResp,	
			M_Axi_RLast		=> M_Axi_RLast,	
			M_Axi_RValid	=> M_Axi_RValid,
			M_Axi_RReady	=> M_Axi_RReady
		);	
		
	-- *** Write Releated Code ***
	g_write : if ImplWrite_g generate
		
		-- Write Data FIFO	
		WrFifo_Rdy	<= WrWconv_Rdy and WrWconvEna;
		fifo_wr_data : entity work.psi_common_sync_fifo
			generic map (
				Width_g			=> DataWidth_g,
				Depth_g			=> DataFifoDepth_g,
				AlmFullOn_g		=> false,
				AlmEmptyOn_g	=> false,
				RamStyle_g		=> "auto",
				RamBehavior_g	=> RamBehavior_g
			)
			port map (
				Clk		=> M_Axi_Aclk,
				Rst		=> Rst,
				InData	=> WrDat_Data,
				InVld	=> WrDat_Vld,
				InRdy	=> WrDat_Rdy,
				OutData	=> WrFifo_Data,
				OutVld	=> WrFifo_Vld,
				OutRdy	=> WrFifo_Rdy
			);	
			
		-- Write Data With Conversion
		WrWconv_Vld <= WrWconvEna and WrFifo_Vld;
		WrData_Rdy <= AxiWrDat_Rdy and WrDataEna;
		wc_wr : entity work.psi_common_wconv_n2xn
			generic map (
				InWidth_g	=> DataWidth_g,
				OutWidth_g	=> AxiDataWidth_g
			)
			port map (
				Clk			=> M_Axi_Aclk,
				Rst			=> Rst,
				InVld		=> WrWconv_Vld,
				InRdy		=> WrWconv_Rdy,
				InData		=> WrFifo_Data,
				InLast		=> WrWconv_Last,
				OutVld		=> WrData_Vld,
				OutRdy		=> WrData_Rdy,
				OutData		=> WrData_Data,
				OutLast		=> WrData_Last,
				OutWe		=> WrData_We
			);
	end generate;
	g_nwrite : if not ImplWrite_g generate
		WrDat_Rdy 	<= '0';
	end generate;

	
	-- *** Read Releated Code ***
	g_read : if ImplRead_g generate			
		-- Read Data FIFO
		fifo_rd_data : entity work.psi_common_sync_fifo
		generic map (
			Width_g			=> DataWidth_g,
			Depth_g			=> DataFifoDepth_g,
			AlmFullOn_g		=> false,
			AlmEmptyOn_g	=> false,
			RamStyle_g		=> "auto",
			RamBehavior_g	=> RamBehavior_g
		)
		port map (
			Clk		=> M_Axi_Aclk,
			Rst		=> Rst,
			InData	=> RdFifo_Data,
			InVld	=> RdFifo_Vld,
			InRdy	=> RdFifo_Rdy,
			OutData	=> RdDat_Data,
			OutVld	=> RdDat_Vld,
			OutRdy	=> RdDat_Rdy
		);
	end generate;
	g_nread : if not ImplRead_g generate
		RdDat_Vld 	<= '0';
		RdDat_Data	<= (others => '0');
	end generate;	
 
end rtl;
