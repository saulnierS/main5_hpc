#A modifier en fonction du fichier qu on veut lire
nom="save.txt"
import matplotlib.pyplot as plt
import numpy as np
from scipy.interpolate import interp1d
import re

#Expressions regulieres de chaque question
RE_cpu = re.compile("^(.+) Taille_A: (\d+), Taille_B: (\d+), Taille_M: (\d+), Temps: (\d+).(\d+), verif: .*(\d+)")
RE_gpu_merge_threadsOnly = re.compile("^(.+) Taille_A: (\d+), Taille_B: (\d+), Taille_M: (\d+), nbthreads: (\d+), Temps: (\d+).(\d+), verif: .*(\d+)") 
RE_gpu_merge = re.compile("^(.+) Taille_A: (\d+), Taille_B: (\d+), Taille_M: (\d+), nbthreads: (\d+), numblocks: (\d+), Temps: (\d+).(\d+), verif: .*(\d+)") 
RE_gpu_sort = re.compile("^(.+) Taille_M: (\d+), nbthreads: (\d+), numblocks: (\d+), Temps: (\d+).(\d+), verif: .*(\d+)") 


def nb_line(nom):
    file = open(nom, "r")
    c=0
    for i in file:
        c=c+1
    file.close()
    return c

def traitement_RE(chaine):
    choix=-1
    match = RE_cpu.match(chaine)
    if match is not None:
        nom = match.group(1)
        size_A = int(match.group(2))
        size_B = int(match.group(3))
        size_M = int(match.group(4))
        temps = float(int(match.group(5))+int(match.group(6))*10**-5)
        verif = int(match.group(7))
        choix = 0


    match = RE_gpu_merge_threadsOnly.match(chaine)
    if match is not None:
        nom = match.group(1)
        size_A = int(match.group(2))
        size_B = int(match.group(3))
        size_M = int(match.group(4))
        nbthreads = int(match.group(5))
        temps = float(int(match.group(6))+int(match.group(7))*10**-5)
        verif = int(match.group(8))
        choix = 1

    match = RE_gpu_merge.match(chaine)
    if match is not None:
        nom = match.group(1)
        size_A = int(match.group(2))
        size_B = int(match.group(3))
        size_M = int(match.group(4))
        nbthreads = int(match.group(5))
        numblocks = int(match.group(6))
        temps = float(int(match.group(7))+int(match.group(8))*10**-5)
        verif = int(match.group(9))
        choix = 2


    match = RE_gpu_sort.match(chaine)
    if match is not None:
        nom = match.group(1)
        size_M = int(match.group(2))
        nbthreads = int(match.group(3))
        numblocks = int(match.group(4))
        temps = float(int(match.group(5))+int(match.group(6))*10**-5)
        verif = int(match.group(7))
        choix = 3

    print(choix)
    dico={}
    if choix==0:
        dico={"nom": nom, "taille A": size_A, "taille_B": size_B, "taille_M": size_M, "temps": temps, "verif": verif}
    if choix==1:
        dico={"nom": nom, "taille A": size_A, "taille_B": size_B, "taille_M": size_M, "threads": nbthreads, "temps": temps, "verif": verif}
    if choix==2:
        dico={"nom": nom, "taille A": size_A, "taille_B": size_B, "taille_M": size_M, "threads": nbthreads,"blocks": numblocks, "temps": temps, "verif": verif}
    if choix==3:
        dico={"nom": nom, "taille_M": size_M, "threads": nbthreads,"blocks": numblocks, "temps": temps, "verif": verif}
    return dico

def graphique(x,y,x_title='temps',y_title='N',title=''):
    plt.figure("HPC")
    plt.plot(x,y,"o:")
    # plt.legend(['size','time'], loc='best')
    plt.xlabel(x_title)
    plt.ylabel(y_title)
    plt.title(title)

####################
#MAIN
####################
taille=nb_line(nom)
file = open(nom, "r")
c=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        c=c+1
file.close()
time=np.zeros(c)
size=np.zeros(c)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time[i]=save['temps']
        size[i]=save['taille_M']
        i=i+1

file.close()
graphique(time,size)
plt.show()