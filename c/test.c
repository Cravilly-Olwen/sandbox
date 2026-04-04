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