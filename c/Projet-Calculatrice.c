/* Concept : Mini-calculatrice */
#include <stdio.h>
float calculer(float a, float b, char op){
    switch (op){
    case '+':
        return a + b;
        break;

    case '-':
        return a - b;

    case '*':
        return a * b;

    case '/':
        if(b == 0){
            printf("Pas de 0");
            printf("\n");
        }else{
            return a / b;
        }
    }
    return 0;
}

int main(){
    float a;
    float b;
    char op;
    char choose;

    do{

        printf("Choisir a : ");
        scanf("%f", &a);

        printf("Choisir op : ");
        scanf(" %c", &op);

        printf("Choisir b : ");
        scanf("%f", &b);

        float resultat = calculer(a, b, op);

        printf("Afficher l'operation : %f ", resultat );
        printf("\n");

        printf("Vous voullez continuer o/n : ");
        scanf(" %c", &choose);
        printf("\n");

    } while (choose == 'o');
    
    return 0;
}