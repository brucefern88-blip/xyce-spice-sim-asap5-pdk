module counter (clk,
    en,
    load,
    overflow,
    rst_n,
    count,
    data_in);
 input clk;
 input en;
 input load;
 output overflow;
 input rst_n;
 output [15:0] count;
 input [15:0] data_in;

 wire _000_;
 wire _001_;
 wire _002_;
 wire _003_;
 wire _004_;
 wire _005_;
 wire _006_;
 wire _007_;
 wire _008_;
 wire _009_;
 wire _010_;
 wire _011_;
 wire _012_;
 wire _013_;
 wire _014_;
 wire _015_;
 wire _016_;
 wire _017_;
 wire _018_;
 wire _019_;
 wire _020_;
 wire _021_;
 wire _022_;
 wire _023_;
 wire _024_;
 wire _025_;
 wire _026_;
 wire _027_;
 wire _028_;
 wire _029_;
 wire _030_;
 wire _031_;
 wire _032_;
 wire _033_;
 wire _034_;
 wire _035_;
 wire _036_;
 wire _037_;
 wire _038_;
 wire _039_;
 wire _040_;
 wire _041_;
 wire _042_;
 wire _043_;
 wire _044_;
 wire _045_;
 wire _046_;
 wire _047_;
 wire _048_;
 wire _049_;
 wire _050_;
 wire _051_;
 wire _052_;
 wire _053_;
 wire _054_;
 wire _055_;
 wire _056_;
 wire _057_;
 wire _058_;
 wire _059_;
 wire _060_;
 wire _061_;
 wire _062_;
 wire _063_;
 wire _064_;
 wire _065_;
 wire _066_;
 wire _067_;
 wire _068_;
 wire _069_;
 wire _070_;
 wire _071_;
 wire _072_;
 wire _073_;
 wire _074_;
 wire _075_;
 wire _076_;
 wire _077_;
 wire _078_;
 wire _079_;
 wire _080_;
 wire _081_;
 wire _082_;
 wire _083_;
 wire _084_;
 wire _085_;
 wire clknet_0_clk;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;

 TAPCELL_X1 PHY_EDGE_ROW_0_Left_63 ();
 TAPCELL_X1 PHY_EDGE_ROW_0_Right_0 ();
 TAPCELL_X1 PHY_EDGE_ROW_10_Left_73 ();
 TAPCELL_X1 PHY_EDGE_ROW_10_Right_10 ();
 TAPCELL_X1 PHY_EDGE_ROW_11_Left_74 ();
 TAPCELL_X1 PHY_EDGE_ROW_11_Right_11 ();
 TAPCELL_X1 PHY_EDGE_ROW_12_Left_75 ();
 TAPCELL_X1 PHY_EDGE_ROW_12_Right_12 ();
 TAPCELL_X1 PHY_EDGE_ROW_13_Left_76 ();
 TAPCELL_X1 PHY_EDGE_ROW_13_Right_13 ();
 TAPCELL_X1 PHY_EDGE_ROW_14_Left_77 ();
 TAPCELL_X1 PHY_EDGE_ROW_14_Right_14 ();
 TAPCELL_X1 PHY_EDGE_ROW_15_Left_78 ();
 TAPCELL_X1 PHY_EDGE_ROW_15_Right_15 ();
 TAPCELL_X1 PHY_EDGE_ROW_16_Left_79 ();
 TAPCELL_X1 PHY_EDGE_ROW_16_Right_16 ();
 TAPCELL_X1 PHY_EDGE_ROW_17_Left_80 ();
 TAPCELL_X1 PHY_EDGE_ROW_17_Right_17 ();
 TAPCELL_X1 PHY_EDGE_ROW_18_Left_81 ();
 TAPCELL_X1 PHY_EDGE_ROW_18_Right_18 ();
 TAPCELL_X1 PHY_EDGE_ROW_19_Left_82 ();
 TAPCELL_X1 PHY_EDGE_ROW_19_Right_19 ();
 TAPCELL_X1 PHY_EDGE_ROW_1_Left_64 ();
 TAPCELL_X1 PHY_EDGE_ROW_1_Right_1 ();
 TAPCELL_X1 PHY_EDGE_ROW_20_Left_83 ();
 TAPCELL_X1 PHY_EDGE_ROW_20_Right_20 ();
 TAPCELL_X1 PHY_EDGE_ROW_21_Left_84 ();
 TAPCELL_X1 PHY_EDGE_ROW_21_Right_21 ();
 TAPCELL_X1 PHY_EDGE_ROW_22_Left_85 ();
 TAPCELL_X1 PHY_EDGE_ROW_22_Right_22 ();
 TAPCELL_X1 PHY_EDGE_ROW_23_Left_86 ();
 TAPCELL_X1 PHY_EDGE_ROW_23_Right_23 ();
 TAPCELL_X1 PHY_EDGE_ROW_24_Left_87 ();
 TAPCELL_X1 PHY_EDGE_ROW_24_Right_24 ();
 TAPCELL_X1 PHY_EDGE_ROW_25_Left_88 ();
 TAPCELL_X1 PHY_EDGE_ROW_25_Right_25 ();
 TAPCELL_X1 PHY_EDGE_ROW_26_Left_89 ();
 TAPCELL_X1 PHY_EDGE_ROW_26_Right_26 ();
 TAPCELL_X1 PHY_EDGE_ROW_27_Left_90 ();
 TAPCELL_X1 PHY_EDGE_ROW_27_Right_27 ();
 TAPCELL_X1 PHY_EDGE_ROW_28_Left_91 ();
 TAPCELL_X1 PHY_EDGE_ROW_28_Right_28 ();
 TAPCELL_X1 PHY_EDGE_ROW_29_Left_92 ();
 TAPCELL_X1 PHY_EDGE_ROW_29_Right_29 ();
 TAPCELL_X1 PHY_EDGE_ROW_2_Left_65 ();
 TAPCELL_X1 PHY_EDGE_ROW_2_Right_2 ();
 TAPCELL_X1 PHY_EDGE_ROW_30_Left_93 ();
 TAPCELL_X1 PHY_EDGE_ROW_30_Right_30 ();
 TAPCELL_X1 PHY_EDGE_ROW_31_Left_94 ();
 TAPCELL_X1 PHY_EDGE_ROW_31_Right_31 ();
 TAPCELL_X1 PHY_EDGE_ROW_32_Left_95 ();
 TAPCELL_X1 PHY_EDGE_ROW_32_Right_32 ();
 TAPCELL_X1 PHY_EDGE_ROW_33_Left_96 ();
 TAPCELL_X1 PHY_EDGE_ROW_33_Right_33 ();
 TAPCELL_X1 PHY_EDGE_ROW_34_Left_97 ();
 TAPCELL_X1 PHY_EDGE_ROW_34_Right_34 ();
 TAPCELL_X1 PHY_EDGE_ROW_35_Left_98 ();
 TAPCELL_X1 PHY_EDGE_ROW_35_Right_35 ();
 TAPCELL_X1 PHY_EDGE_ROW_36_Left_99 ();
 TAPCELL_X1 PHY_EDGE_ROW_36_Right_36 ();
 TAPCELL_X1 PHY_EDGE_ROW_37_Left_100 ();
 TAPCELL_X1 PHY_EDGE_ROW_37_Right_37 ();
 TAPCELL_X1 PHY_EDGE_ROW_38_Left_101 ();
 TAPCELL_X1 PHY_EDGE_ROW_38_Right_38 ();
 TAPCELL_X1 PHY_EDGE_ROW_39_Left_102 ();
 TAPCELL_X1 PHY_EDGE_ROW_39_Right_39 ();
 TAPCELL_X1 PHY_EDGE_ROW_3_Left_66 ();
 TAPCELL_X1 PHY_EDGE_ROW_3_Right_3 ();
 TAPCELL_X1 PHY_EDGE_ROW_40_Left_103 ();
 TAPCELL_X1 PHY_EDGE_ROW_40_Right_40 ();
 TAPCELL_X1 PHY_EDGE_ROW_41_Left_104 ();
 TAPCELL_X1 PHY_EDGE_ROW_41_Right_41 ();
 TAPCELL_X1 PHY_EDGE_ROW_42_Left_105 ();
 TAPCELL_X1 PHY_EDGE_ROW_42_Right_42 ();
 TAPCELL_X1 PHY_EDGE_ROW_43_Left_106 ();
 TAPCELL_X1 PHY_EDGE_ROW_43_Right_43 ();
 TAPCELL_X1 PHY_EDGE_ROW_44_Left_107 ();
 TAPCELL_X1 PHY_EDGE_ROW_44_Right_44 ();
 TAPCELL_X1 PHY_EDGE_ROW_45_Left_108 ();
 TAPCELL_X1 PHY_EDGE_ROW_45_Right_45 ();
 TAPCELL_X1 PHY_EDGE_ROW_46_Left_109 ();
 TAPCELL_X1 PHY_EDGE_ROW_46_Right_46 ();
 TAPCELL_X1 PHY_EDGE_ROW_47_Left_110 ();
 TAPCELL_X1 PHY_EDGE_ROW_47_Right_47 ();
 TAPCELL_X1 PHY_EDGE_ROW_48_Left_111 ();
 TAPCELL_X1 PHY_EDGE_ROW_48_Right_48 ();
 TAPCELL_X1 PHY_EDGE_ROW_49_Left_112 ();
 TAPCELL_X1 PHY_EDGE_ROW_49_Right_49 ();
 TAPCELL_X1 PHY_EDGE_ROW_4_Left_67 ();
 TAPCELL_X1 PHY_EDGE_ROW_4_Right_4 ();
 TAPCELL_X1 PHY_EDGE_ROW_50_Left_113 ();
 TAPCELL_X1 PHY_EDGE_ROW_50_Right_50 ();
 TAPCELL_X1 PHY_EDGE_ROW_51_Left_114 ();
 TAPCELL_X1 PHY_EDGE_ROW_51_Right_51 ();
 TAPCELL_X1 PHY_EDGE_ROW_52_Left_115 ();
 TAPCELL_X1 PHY_EDGE_ROW_52_Right_52 ();
 TAPCELL_X1 PHY_EDGE_ROW_53_Left_116 ();
 TAPCELL_X1 PHY_EDGE_ROW_53_Right_53 ();
 TAPCELL_X1 PHY_EDGE_ROW_54_Left_117 ();
 TAPCELL_X1 PHY_EDGE_ROW_54_Right_54 ();
 TAPCELL_X1 PHY_EDGE_ROW_55_Left_118 ();
 TAPCELL_X1 PHY_EDGE_ROW_55_Right_55 ();
 TAPCELL_X1 PHY_EDGE_ROW_56_Left_119 ();
 TAPCELL_X1 PHY_EDGE_ROW_56_Right_56 ();
 TAPCELL_X1 PHY_EDGE_ROW_57_Left_120 ();
 TAPCELL_X1 PHY_EDGE_ROW_57_Right_57 ();
 TAPCELL_X1 PHY_EDGE_ROW_58_Left_121 ();
 TAPCELL_X1 PHY_EDGE_ROW_58_Right_58 ();
 TAPCELL_X1 PHY_EDGE_ROW_59_Left_122 ();
 TAPCELL_X1 PHY_EDGE_ROW_59_Right_59 ();
 TAPCELL_X1 PHY_EDGE_ROW_5_Left_68 ();
 TAPCELL_X1 PHY_EDGE_ROW_5_Right_5 ();
 TAPCELL_X1 PHY_EDGE_ROW_60_Left_123 ();
 TAPCELL_X1 PHY_EDGE_ROW_60_Right_60 ();
 TAPCELL_X1 PHY_EDGE_ROW_61_Left_124 ();
 TAPCELL_X1 PHY_EDGE_ROW_61_Right_61 ();
 TAPCELL_X1 PHY_EDGE_ROW_62_Left_125 ();
 TAPCELL_X1 PHY_EDGE_ROW_62_Right_62 ();
 TAPCELL_X1 PHY_EDGE_ROW_6_Left_69 ();
 TAPCELL_X1 PHY_EDGE_ROW_6_Right_6 ();
 TAPCELL_X1 PHY_EDGE_ROW_7_Left_70 ();
 TAPCELL_X1 PHY_EDGE_ROW_7_Right_7 ();
 TAPCELL_X1 PHY_EDGE_ROW_8_Left_71 ();
 TAPCELL_X1 PHY_EDGE_ROW_8_Right_8 ();
 TAPCELL_X1 PHY_EDGE_ROW_9_Left_72 ();
 TAPCELL_X1 PHY_EDGE_ROW_9_Right_9 ();
 INV_X1 _086_ (.A(count[9]),
    .ZN(_033_));
 INV_X1 _087_ (.A(load),
    .ZN(_034_));
 INV_X1 _088_ (.A(data_in[3]),
    .ZN(_035_));
 INV_X1 _089_ (.A(en),
    .ZN(_036_));
 NAND3_X1 _090_ (.A1(count[4]),
    .A2(count[3]),
    .A3(count[2]),
    .ZN(_037_));
 NAND2_X1 _091_ (.A1(count[6]),
    .A2(count[7]),
    .ZN(_038_));
 NAND4_X1 _092_ (.A1(count[8]),
    .A2(count[5]),
    .A3(count[0]),
    .A4(count[1]),
    .ZN(_039_));
 NOR3_X1 _093_ (.A1(_037_),
    .A2(_038_),
    .A3(_039_),
    .ZN(_040_));
 NOR4_X1 _094_ (.A1(_033_),
    .A2(_037_),
    .A3(_038_),
    .A4(_039_),
    .ZN(_041_));
 AND4_X1 _095_ (.A1(count[12]),
    .A2(count[10]),
    .A3(count[11]),
    .A4(_041_),
    .ZN(_042_));
 AND3_X1 _096_ (.A1(count[13]),
    .A2(count[14]),
    .A3(_042_),
    .ZN(_043_));
 NAND4_X1 _097_ (.A1(count[13]),
    .A2(count[14]),
    .A3(count[15]),
    .A4(_042_),
    .ZN(_044_));
 NOR2_X1 _098_ (.A1(_036_),
    .A2(_044_),
    .ZN(overflow));
 AND3_X1 _099_ (.A1(count[0]),
    .A2(count[1]),
    .A3(en),
    .ZN(_045_));
 AOI21_X1 _100_ (.A(count[3]),
    .B1(count[2]),
    .B2(_045_),
    .ZN(_046_));
 AND4_X1 _101_ (.A1(count[3]),
    .A2(count[2]),
    .A3(count[0]),
    .A4(count[1]),
    .ZN(_047_));
 AND2_X1 _102_ (.A1(en),
    .A2(_047_),
    .ZN(_048_));
 OR3_X1 _103_ (.A1(load),
    .A2(_046_),
    .A3(_048_),
    .ZN(_049_));
 OAI21_X1 _104_ (.A(_049_),
    .B1(_035_),
    .B2(_034_),
    .ZN(_001_));
 XOR2_X1 _105_ (.A(count[2]),
    .B(_045_),
    .Z(_050_));
 MUX2_X1 _106_ (.A(data_in[2]),
    .B(_050_),
    .S(_034_),
    .Z(_002_));
 AOI21_X1 _107_ (.A(count[1]),
    .B1(en),
    .B2(count[0]),
    .ZN(_051_));
 NOR2_X1 _108_ (.A1(_045_),
    .A2(_051_),
    .ZN(_052_));
 MUX2_X1 _109_ (.A(data_in[1]),
    .B(_052_),
    .S(_034_),
    .Z(_003_));
 NOR2_X1 _110_ (.A1(load),
    .A2(_036_),
    .ZN(_053_));
 NAND2_X1 _111_ (.A1(_034_),
    .A2(en),
    .ZN(_054_));
 NOR2_X1 _112_ (.A1(load),
    .A2(en),
    .ZN(_055_));
 AOI222_X1 _113_ (.A1(load),
    .A2(data_in[0]),
    .B1(_053_),
    .B2(_000_),
    .C1(_055_),
    .C2(count[0]),
    .ZN(_056_));
 INV_X1 _114_ (.A(_056_),
    .ZN(_004_));
 AND4_X1 _115_ (.A1(count[6]),
    .A2(count[4]),
    .A3(count[5]),
    .A4(_047_),
    .ZN(_057_));
 AND4_X1 _116_ (.A1(count[9]),
    .A2(count[8]),
    .A3(count[7]),
    .A4(_057_),
    .ZN(_058_));
 NAND2_X1 _117_ (.A1(count[10]),
    .A2(_058_),
    .ZN(_059_));
 NAND3_X1 _118_ (.A1(count[10]),
    .A2(count[11]),
    .A3(_058_),
    .ZN(_060_));
 NAND4_X1 _119_ (.A1(count[12]),
    .A2(count[10]),
    .A3(count[11]),
    .A4(_058_),
    .ZN(_061_));
 AOI21_X1 _120_ (.A(count[14]),
    .B1(_042_),
    .B2(count[13]),
    .ZN(_062_));
 OR2_X1 _121_ (.A1(_043_),
    .A2(_054_),
    .ZN(_063_));
 AOI22_X1 _122_ (.A1(data_in[14]),
    .A2(load),
    .B1(_055_),
    .B2(count[14]),
    .ZN(_064_));
 OAI21_X1 _123_ (.A(_064_),
    .B1(_063_),
    .B2(_062_),
    .ZN(_005_));
 XOR2_X1 _124_ (.A(count[13]),
    .B(_061_),
    .Z(_065_));
 AOI22_X1 _125_ (.A1(load),
    .A2(data_in[13]),
    .B1(_055_),
    .B2(count[13]),
    .ZN(_066_));
 OAI21_X1 _126_ (.A(_066_),
    .B1(_065_),
    .B2(_054_),
    .ZN(_006_));
 AOI22_X1 _127_ (.A1(load),
    .A2(data_in[12]),
    .B1(_055_),
    .B2(count[12]),
    .ZN(_067_));
 XOR2_X1 _128_ (.A(count[12]),
    .B(_060_),
    .Z(_068_));
 OAI21_X1 _129_ (.A(_067_),
    .B1(_068_),
    .B2(_054_),
    .ZN(_007_));
 AOI22_X1 _130_ (.A1(load),
    .A2(data_in[11]),
    .B1(_055_),
    .B2(count[11]),
    .ZN(_069_));
 XOR2_X1 _131_ (.A(count[11]),
    .B(_059_),
    .Z(_070_));
 OAI21_X1 _132_ (.A(_069_),
    .B1(_070_),
    .B2(_054_),
    .ZN(_008_));
 AOI22_X1 _133_ (.A1(load),
    .A2(data_in[10]),
    .B1(_055_),
    .B2(count[10]),
    .ZN(_017_));
 OAI21_X1 _134_ (.A(_059_),
    .B1(_041_),
    .B2(count[10]),
    .ZN(_018_));
 OAI21_X1 _135_ (.A(_017_),
    .B1(_018_),
    .B2(_054_),
    .ZN(_009_));
 AOI22_X1 _136_ (.A1(load),
    .A2(data_in[9]),
    .B1(_055_),
    .B2(count[9]),
    .ZN(_019_));
 OAI21_X1 _137_ (.A(_053_),
    .B1(_040_),
    .B2(count[9]),
    .ZN(_020_));
 OAI21_X1 _138_ (.A(_019_),
    .B1(_020_),
    .B2(_058_),
    .ZN(_010_));
 NAND2_X1 _139_ (.A1(count[4]),
    .A2(_048_),
    .ZN(_021_));
 AND3_X1 _140_ (.A1(count[4]),
    .A2(count[5]),
    .A3(_048_),
    .ZN(_022_));
 NAND2_X1 _141_ (.A1(count[6]),
    .A2(_022_),
    .ZN(_023_));
 NAND3_X1 _142_ (.A1(count[7]),
    .A2(en),
    .A3(_057_),
    .ZN(_024_));
 XNOR2_X1 _143_ (.A(count[8]),
    .B(_024_),
    .ZN(_025_));
 MUX2_X1 _144_ (.A(data_in[8]),
    .B(_025_),
    .S(_034_),
    .Z(_011_));
 XNOR2_X1 _145_ (.A(count[7]),
    .B(_023_),
    .ZN(_026_));
 MUX2_X1 _146_ (.A(data_in[7]),
    .B(_026_),
    .S(_034_),
    .Z(_012_));
 XOR2_X1 _147_ (.A(count[6]),
    .B(_022_),
    .Z(_027_));
 MUX2_X1 _148_ (.A(data_in[6]),
    .B(_027_),
    .S(_034_),
    .Z(_013_));
 NOR2_X1 _149_ (.A1(count[15]),
    .A2(_043_),
    .ZN(_028_));
 NAND2_X1 _150_ (.A1(_044_),
    .A2(_053_),
    .ZN(_029_));
 AOI22_X1 _151_ (.A1(load),
    .A2(data_in[15]),
    .B1(_055_),
    .B2(count[15]),
    .ZN(_030_));
 OAI21_X1 _152_ (.A(_030_),
    .B1(_029_),
    .B2(_028_),
    .ZN(_014_));
 XNOR2_X1 _153_ (.A(count[5]),
    .B(_021_),
    .ZN(_031_));
 MUX2_X1 _154_ (.A(data_in[5]),
    .B(_031_),
    .S(_034_),
    .Z(_015_));
 XOR2_X1 _155_ (.A(count[4]),
    .B(_048_),
    .Z(_032_));
 MUX2_X1 _156_ (.A(data_in[4]),
    .B(_032_),
    .S(_034_),
    .Z(_016_));
 DFFR_X1 _157_ (.D(_004_),
    .RN(rst_n),
    .CK(clknet_1_0__leaf_clk),
    .Q(count[0]),
    .QN(_000_));
 DFFR_X1 _158_ (.D(_003_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[1]),
    .QN(_083_));
 DFFR_X1 _159_ (.D(_002_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[2]),
    .QN(_084_));
 DFFR_X1 _160_ (.D(_001_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[3]),
    .QN(_085_));
 DFFR_X1 _161_ (.D(_016_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[4]),
    .QN(_071_));
 DFFR_X1 _162_ (.D(_015_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[5]),
    .QN(_072_));
 DFFR_X1 _163_ (.D(_013_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[6]),
    .QN(_074_));
 DFFR_X1 _164_ (.D(_012_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[7]),
    .QN(_075_));
 DFFR_X1 _165_ (.D(_011_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[8]),
    .QN(_076_));
 DFFR_X1 _166_ (.D(_010_),
    .RN(rst_n),
    .CK(clknet_1_1__leaf_clk),
    .Q(count[9]),
    .QN(_077_));
 DFFR_X1 _167_ (.D(_009_),
    .RN(rst_n),
    .CK(clknet_1_0__leaf_clk),
    .Q(count[10]),
    .QN(_078_));
 DFFR_X1 _168_ (.D(_008_),
    .RN(rst_n),
    .CK(clknet_1_0__leaf_clk),
    .Q(count[11]),
    .QN(_079_));
 DFFR_X1 _169_ (.D(_007_),
    .RN(rst_n),
    .CK(clknet_1_0__leaf_clk),
    .Q(count[12]),
    .QN(_080_));
 DFFR_X1 _170_ (.D(_006_),
    .RN(rst_n),
    .CK(clknet_1_0__leaf_clk),
    .Q(count[13]),
    .QN(_081_));
 DFFR_X1 _171_ (.D(_005_),
    .RN(rst_n),
    .CK(clknet_1_0__leaf_clk),
    .Q(count[14]),
    .QN(_082_));
 DFFR_X1 _172_ (.D(_014_),
    .RN(rst_n),
    .CK(clknet_1_0__leaf_clk),
    .Q(count[15]),
    .QN(_073_));
 BUF_X4 clkbuf_0_clk (.A(clk),
    .Z(clknet_0_clk));
 BUF_X4 clkbuf_1_0__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_0__leaf_clk));
 BUF_X4 clkbuf_1_1__f_clk (.A(clknet_0_clk),
    .Z(clknet_1_1__leaf_clk));
 INV_X1 clkload0 (.A(clknet_1_0__leaf_clk));
endmodule
