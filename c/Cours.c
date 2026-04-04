/* Concept : Structure de base " */ 
#include <stdio.h>
int main() {
    printf("Hello, World!\n");
    return 0;
}

/* Concept : Déclaration de variables */ 
#include <stdio.h>
int main(){
    int age = 20;
    float taille = 1.75;

    printf("Age : %d", age);
    printf("\n");
    printf("Taille : %f", taille,"\n");
    return 0;
}

/* Concept : Calculs mathématiques */
#include <stdio.h>
int main(){
    int a = 15;
    int b = 4;

    int somme = a + b;
    int produit = a * b;
    int reste = a % b;

    printf("Somme : %d", somme);
    printf("\n");
    printf("Produit : %d", produit);
    printf("\n");
    printf("Reste : %d", reste);
    return 0;
}

/* Concept : Structures conditionnelles */
#include <stdio.h>
int main(){
    int note;
    printf("Mettez la note entre 0 et 20 : ");
    scanf("%d", &note);

    if (note >= 10) {
    printf("Admis\n");
    if (note >= 16) {
    printf("Avec mention !\n");
    }
    } else {
    printf("Recalé\n");
    }
    return 0;
}

/* Concept : Répétition conditionnelle */
#include <stdio.h>
int main(){
    int i= 1;
    while (i < 11){
        printf("Valeur : %d", i);
        printf("\n");
        i++;
    }
    return 0;
}

/* Concept : Répétition avec compteur */
#include <stdio.h>
int main(){
    int somme = 0;

    for(int i = 0; i <= 100; i++){
        somme = somme + i;
    }
    printf("Somme : %d", somme);
    return 0;
}

/* Concept : Collections de données */
#include <stdio.h>
int main(){
    float result;
    int somme = 0;

    int tab[5] = {10, 20, 30, 40, 50};
    for(int i = 0; i < 5; i++){
        printf("Element : %d", tab[i]);
        printf("\n");
        somme = somme + tab[i];
    }

    result = somme / 5.0;
    printf("Moyenne : %f", result);
    printf("\n");
    return 0;
}

/* Concept : Manipulation de texte */
#include <stdio.h>
#include <string.h>
int main(){
    char prenom[] = "Olwen";
    int longeur = strlen(prenom);

    printf("Prenom : %s", prenom);
    printf("\n");
    printf("Longeur : %lu", longeur);
    return 0;
}

/* Concept : Réutilisation de code */
#include <stdio.h>
int carre(int a){
    return a * a;
}
void afficherTable(int nombre){
    for (int i = 1; i <= 10; i++){
        printf("%d x %d = %d", nombre, i, nombre * i);
        printf("\n");
    }
}
int main(){
    int resultat = carre(5);
    printf("Resultat du carre de 5 : %d\n", resultat);
    printf("Affichage de la table :\n");
    afficherTable(5);
    return 0;
}

