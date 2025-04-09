within ;
model DoubleUTubeField_5x5_6m

  extends Modelica.Icons.Example;
  package Medium = AixLib.Media.Water;

  parameter Modelica.Units.SI.Temperature T_start=273.15 + 11.0
    "Initial temperature of the sandbox";

  constant Real mSenFac = 1.59186
  "Scaling factor for the borehole capacitances, modified to account for the thermal mass of the pipes and the borehole casing";

  AixLib.Fluid.Geothermal.Borefields.TwoUTubes borHol(
    redeclare package Medium = Medium (redeclare record FluidConstants =
            Modelica.Media.Interfaces.Types.Basic.FluidConstants),
    nSeg=10,                           borFieDat=
    borFieDat,
    tLoaAgg=3600,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial,
    mSenFac=mSenFac,
    TExt0_start=T_start,
    dT_dz=0) "Borehole"
    annotation (Placement(transformation(extent={{40,-30},{60,-10}})));
  AixLib.Fluid.Movers.FlowControlled_m_flow pum(
    redeclare package Medium = Medium,
    T_start=T_start,
    addPowerToMedium=false,
    use_inputFilter=false,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
    m_flow_nominal=borFieDat.conDat.mBorFie_flow_nominal,
    nominalValuesDefineDefaultPressureCurve=true,
    inputType=AixLib.Fluid.Types.InputType.Continuous)
    annotation (Placement(transformation(extent={{-20,-10},{0,-30}})));
  AixLib.Fluid.Sensors.TemperatureTwoPort TBorFieIn(
    redeclare package Medium = Medium,
    T_start=T_start,
    m_flow_nominal=borFieDat.conDat.mBorFie_flow_nominal,
    tau=0)
    "Inlet temperature of the borefield"
    annotation (Placement(transformation(extent={{10,-30},{30,-10}})));
  AixLib.Fluid.Sensors.TemperatureTwoPort TBorFieOut(
    redeclare package Medium = Medium,
    T_start=T_start,
    m_flow_nominal=borFieDat.conDat.mBorFie_flow_nominal,
    tau=0)
    "Outlet temperature of the borefield"
    annotation (Placement(transformation(extent={{70,-30},{90,-10}})));
  AixLib.Fluid.Geothermal.Borefields.Validation.BaseClasses.SandBox_Borefield borFieDat(
    filDat=AixLib.Fluid.Geothermal.Borefields.Validation.BaseClasses.SandBox_Filling(kFil=0.63),
    soiDat=
        AixLib.Fluid.Geothermal.Borefields.Validation.BaseClasses.SandBox_Soil(),
    conDat(borCon = AixLib.Fluid.Geothermal.Borefields.Types.BoreholeConfiguration.DoubleUTubeParallel, use_Rb = true, Rb = 0.135, hBor = 100, rBor = 0.075, nBor = 25, cooBor = [0, 0; 0, 6; 0, 12; 0, 18; 0, 24; 6, 0; 6, 6; 6, 12; 6, 18; 6, 24; 12, 0; 12, 6; 12, 12; 12, 18; 12, 24; 18, 0; 18, 6; 18, 12; 18, 18; 18, 24; 24, 0; 24, 6; 24, 12; 24, 18; 24, 24], rTub = 0.032, kTub = 0.4, eTub = 0.0032, xC = 0.035))                                                                      "Borefield data"
    annotation (Placement(transformation(extent={{-100,-100},{-80,-80}})));

  AixLib.Fluid.Sources.Boundary_ph sin(
    redeclare package Medium = Medium,
    nPorts=1) "Sink"
    annotation (Placement(transformation(extent={{60,0},{80,20}})));
  AixLib.Fluid.HeatExchangers.HeaterCooler_u hea(
    redeclare package Medium = Medium,
    dp_nominal=10000,
    show_T=true,
    energyDynamics=Modelica.Fluid.Types.Dynamics.SteadyState,
    T_start=T_start,
    Q_flow_nominal=1,
    m_flow_nominal=borFieDat.conDat.mBorFie_flow_nominal,
    m_flow(start=borFieDat.conDat.mBorFie_flow_nominal),
    p_start=100000) "Heater"
    annotation (Placement(transformation(extent={{-50,-30},{-30,-10}})));
  Modelica.Blocks.Sources.CombiTimeTable profile_year(
    tableOnFile=true,
    tableName="data",
    offset={0,0},
    columns={2,3},
    fileName= "/mnt/Daten/Forschung/Projekte/2022_MultiSource/Vergleich FEFLOW/Sondenfeld/Profile/Entzug_Sondenfeld_5Jahre_Feld5x5_Stundenprofil.tsv")
    annotation (Placement(transformation(extent={{-94,-6},{-74,14}})));
equation
  connect(TBorFieIn.port_b, borHol.port_a)
    annotation (Line(points={{30,-20},{40,-20}},   color={0,127,255}));
  connect(borHol.port_b, TBorFieOut.port_a)
    annotation (Line(points={{60,-20},{70,-20}},          color={0,127,255}));
  connect(pum.port_b, TBorFieIn.port_a) annotation (Line(points={{0,-20},{10,-20}},
                                         color={0,127,255}));
  connect(sin.ports[1], TBorFieOut.port_b) annotation (Line(points={{80,10},{100,
          10},{100,-20},{90,-20}},color={0,127,255}));
  connect(hea.port_b, pum.port_a)
    annotation (Line(points={{-30,-20},{-20,-20}},     color={0,127,255}));
  connect(hea.port_a, TBorFieOut.port_b) annotation (Line(points={{-50,-20},{-100,
          -20},{-100,40},{100,40},{100,-20},{90,-20}},
                                      color={0,127,255}));
  connect(profile_year.y[1], hea.u) annotation (Line(points={{-73,4},{-58,4},{-58,
          -14},{-52,-14}}, color={0,0,127}));
  connect(profile_year.y[2], pum.m_flow_in) annotation (Line(points={{-73,4},{
          -66,4},{-66,-38},{-10,-38},{-10,-32}},
                                             color={0,0,127}));
  annotation (experiment(
      StopTime=157680000,
      Interval=3600,
      Tolerance=1e-06,
      __Dymola_Algorithm="Dassl"),
  __Dymola_Commands(file=
          "Resources/Scripts/Dymola/Fluid/Geothermal/Borefields/Validation/Sandbox.mos"
        "Simulate and Plot"),
Documentation(info="<html>
<p>
This validation case simulates the experiment of Beier et al. (2011). Measured
experimental data is taken from the reference.
</p>
<p>
The experiment consists in the injection of heat at an average rate of 1142 W
in a 18 m long borehole over a period 52 h. Dimensions and thermal properties
reported by Beier et al. (2011) are used in the model. The authors conducted
multiple independent measurements of soil thermal conductivity. The average of
reported values (2.88 W/m-K) is used here. Finally, the filling material thermal
capacity and density was not reported. Values were chosen from the estimated
volumetric heat capacity used by Pasquier and Marcotte (2014).
</p>
<p>
The construction of the borehole is non-conventional: the borehole is
contained within an aluminum pipe that acts as the borehole wall. As this
modifies the thermal resistances inside the borehole, the values evaluated by
the multipole method are modified to obtain the effective borehole thermal
resistance reported by Beier et al. (2011).
<h4>References</h4>
<p>
Beier, R.A., Smith, M.D. and Spitler, J.D. 2011. <i>Reference data sets for
vertical borehole ground heat exchanger models and thermal response test
analysis</i>. Geothermics 40: 79-85.
</p>
<p>
Pasquier, P., and Marcotte, D. 2014. <i>Joint use of quasi-3D response model and
spectral method to simulate borehole heat exchanger</i>. Geothermics 51:
281-299.
</p>
</html>", revisions="<html>
<ul>
<li>
July 18, 2018, by Massimo Cimmino:<br/>
First implementation.
</li>
</ul>
</html>"),
    Diagram(coordinateSystem(extent={{-120,-120},{120,120}})),
    uses(Modelica(version="4.0.0"), AixLib(version="1.3.2")),
    version="1",
    conversion(noneFromVersion=""));
end DoubleUTubeField_5x5_6m;