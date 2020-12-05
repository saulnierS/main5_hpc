import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import interp1d
import re


def nb_line(nom):
    file = open(nom, "r")
    c=0
    for i in file:
        c=c+1
    file.close()
    return c

exp_reg = re.compile("^Code_sequentiel Taille_A: (\d+), Taille_B: (\d+), Taille_M: (\d+), Temps: (\d+).(\d+), verif:(\d+)")
nom="code_seq.txt"
longueur=nb_line(nom)
time=np.zeros(longueur)
size=np.zeros(longueur)

file = open(nom, "r")
i=0
for line in file:
    match = exp_reg.match(line)
    assert match is not None
    size_A = int(match.group(1))
    size_B = int(match.group(2))
    size_M = int(match.group(3))
    temps = float(int(match.group(4))+int(match.group(5))*10**-5)
    verif = int(match.group(6))
    time[i]=temps
    size[i]=abs(size_A-size_B)
    i=i+1


plt.figure("test")
plt.plot(time,size,"o:")
# plt.legend(['size','time'], loc='best')
plt.xlabel("time")
plt.ylabel("size")
plt.title("Evolution de la taille en fonction du temps")

file.close()
plt.show()