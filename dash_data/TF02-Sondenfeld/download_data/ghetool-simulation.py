from GHEtool import Borefield, GroundConstantTemperature, HourlyGeothermalLoad, FluidData
import numpy as np
import os

import matplotlib
matplotlib.use('QtAgg')  # Alternativ: 'TkAgg' oder 'GTK3Agg'
import matplotlib.pyplot as pl
from dateutil.rrule import DAILY

# var = 'orig'
var = '180kW'
# pvt = '1300'
pvt = '1600'

file_profile = "/mnt/Daten/Forschung/Projekte/2022_MultiSource/Vergleich FEFLOW/Sondenfeld/Profile/Entzug_Sondenfeld_5Jahre_Feld5x5_Tagesprofil_GHE.tsv"
profile_data = np.loadtxt(file_profile, delimiter="\t", skiprows=1)
extraction = profile_data[:,2]

f, ax = pl.subplots()
ax.plot(extraction)

data = GroundConstantTemperature(2.9,  # ground thermal conductivity (W/mK)
                                11,  # initial/undisturbed ground temperature (deg C)
                                1274 * 2000)  # volumetric heat capacity of the ground (J/m3K)

load = HourlyGeothermalLoad(extraction_load=extraction,
                            simulation_period=5)

# create the borefield object
borefield = Borefield(load=load)

# set ground parameters
borefield.set_ground_parameters(data)

fluid = FluidData(k_f=0.5, rho=1032, Cp=3850)
borefield.set_fluid_parameters(fluid)

# set the borehole equivalent resistance
borefield.Rb = 0.135

# set temperature boundaries
borefield.set_max_avg_fluid_temperature(15)     # maximum temperature
borefield.set_min_avg_fluid_temperature(0)   # minimum temperature

# set a rectangular borefield
Nx = 5
Ny = 5
dx = 6
l_sonde = 100 # 100 m
r_sonde = 0.075 # 15 cm
borefield.create_rectangular_borefield(Nx, Ny, dx, dx, l_sonde, 1, r_sonde)

# length = borefield.size(L4_sizing=True)
# print("The borehole length is: ", length, "m")

borefield.print_temperature_profile(legend=True, plot_hourly=True)
temp_fluid_inlet = borefield.results.Tf - 1.65
temp_fluid_outlet = borefield.results.Tf + 1.65

# Alles zusammenführen
time_h = np.arange(0, 5*8760)
data = np.column_stack((time_h, temp_fluid_inlet, temp_fluid_outlet))

# Speichern als TSV
np.savetxt("ghe_result_data.tsv", data, delimiter="\t", header="Zeit [h]\tInlet [C]\tOutlet [C]", comments='', fmt="%.3f")