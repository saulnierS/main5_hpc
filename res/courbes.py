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

def speed_up(A,B):
    if len(A)!=len(B):
        return 0
    taille = len(A)
    res = np.zeros(taille)
    for n in range(taille):
        res[n] = A[n]/B[n]
    return res


####################
#MAIN
####################
# Question 1
nom="mergeSmall_k_thread.txt"
taille=nb_line(nom)
time_question1=np.zeros(taille)
threads_question1=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_question1[i]=save['temps']
        threads_question1[i]=save['threads']
        i=i+1
file.close()

nom="mergeSmall_k_shared_thread.txt"
taille=nb_line(nom)
time_question1_s=np.zeros(taille)
threads_question1_s=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_question1_s[i]=save['temps']
        threads_question1_s[i]=save['threads']
        i=i+1
file.close()


# plt.figure("Question1")
# plt.plot(threads_question1,time_question1,"o:")
# plt.plot(threads_question1_s,time_question1_s,"o:")
# plt.legend(['sans shared','avec shared'], loc='best')
# plt.xlabel('nombre de threads')
# plt.ylabel('temps en ms')
# plt.title('Evolution du temps d execution de mergeSmall_k avec et sans shared \nen fonction du nombre de threads')

plt.figure("Question1 mergeSmall_k")
plt.plot(threads_question1,time_question1,"o:")
plt.xlabel('nombre de threads')
plt.ylabel('temps en ms')
plt.title('Evolution du temps d execution de mergeSmall_k \nen fonction du nombre de threads')


# plt.figure("Question1 special mergeSmall_k_shared")
# plt.plot(threads_question1_s,time_question1_s,"o:")
# plt.xlabel('nombre de threads')
# plt.ylabel('temps en ms')
# plt.title('Evolution du temps d execution de mergeSmall_k_shared \nen fonction du nombre de threads')


# Question 2
nom="code_seq.txt"
taille=nb_line(nom)
time_seq=np.zeros(taille)
size_seq=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_seq[i]=save['temps']
        size_seq[i]=save['taille_M']
        i=i+1
file.close()
nom="mergeBig_k.txt"
taille=nb_line(nom)
time_question2=np.zeros(taille)
size_question2=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_question2[i]=save['temps']
        size_question2[i]=save['taille_M']
        i=i+1
file.close()


plt.figure("Question2")
plt.plot(size_seq,time_seq,"o:")
plt.plot(size_question2,time_question2,"o:")
plt.legend(['code sequentiel','mergeBig_k'], loc='best')
plt.xlabel('taille M')
plt.ylabel('temps en ms')
plt.title('Evolution du temps d execution de mergeBig_k et du code sequentiel \nen fonction du nombre d element a trier')

speed_up=speed_up(time_seq,time_question2)
plt.figure("Question2 speed up")
plt.plot(size_question2,speed_up,"o:")
# plt.legend(['code sequentiel','mergeBig_k'], loc='best')
plt.xlabel('taille M')
plt.ylabel('speed up')
plt.title('Evolution de l acceleration du temps de calcul de mergeBig_k \npar rapport au code sequentiel \nen fonction du nombre d element a trier')

# Question 3
nom="sort.txt"
taille=nb_line(nom)
time_question3=np.zeros(taille)
size_question3=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_question3[i]=save['temps']
        size_question3[i]=save['taille_M']
        i=i+1
file.close()

nom="sort_stream.txt"
taille=nb_line(nom)
time_question3_s=np.zeros(taille)
size_question3_s=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_question3_s[i]=save['temps']
        size_question3_s[i]=save['taille_M']
        i=i+1
file.close()


plt.figure("Question3")
plt.plot(size_question3,time_question3,"o:")
plt.plot(size_question3_s,time_question3_s,"o:")
plt.legend(['sans stream','avec stream'], loc='best')
plt.xlabel('taille M')
plt.ylabel('temps en ms')
plt.title('Evolution du temps d execution de sort avec et sans stream \nen fonction du nombre d element a trier')


plt.figure("Question3 special sort")
plt.plot(size_question3,time_question3,"o:")
plt.xlabel('taille M')
plt.ylabel('temps en ms')
plt.title('Evolution du temps d execution de sort \nen fonction du nombre d element a trier')


plt.figure("Question3 special sort_stream")
plt.plot(size_question3_s,time_question3_s,"o:")
plt.xlabel('taille M')
plt.ylabel('temps en ms')
plt.title('Evolution du temps d execution de sort_stream \nen fonction du nombre d element a trier')

#Question6
nom="mergeBatches.txt"
taille=nb_line(nom)
time_question6=np.zeros(taille)
size_question6=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_question6[i]=save['temps']
        size_question6[i]=save['taille_M']
        i=i+1
file.close()
nom="mergeBatches_seq.txt"
taille=nb_line(nom)
time_question6_seq=np.zeros(taille)
size_question6_seq=np.zeros(taille)  
file = open(nom, "r")
i=0
for line in file:
    save=traitement_RE(line)
    if (save['verif']==1):
        time_question6_seq[i]=save['temps']
        size_question6_seq[i]=save['taille_M']
        i=i+1
file.close()

plt.figure("Question6")
plt.plot(size_question6,time_question6,"o:")
plt.plot(size_question6_seq,time_question6_seq,"o:")
x = np.linspace(1, 26144)
plt.plot(x,x*np.log(x))
plt.plot(size_question3,time_question3,"o:")
plt.ylim(0,7000)
plt.legend(['mergeBatches','mergeBatches sequentielle','trie fusion','sort sans optimisation'], loc='best')
plt.xlabel('taille M')
plt.ylabel('temps en ms')
plt.title('Evolution du temps d execution de mergeBatches \nen fonction du nombre d element a trier')


plt.show()