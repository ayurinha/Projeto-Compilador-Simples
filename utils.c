/* UNIFAL = Universida de Federal de Alfenas.
BACHARELADO EM CIENCIA DA COMPUTACAO.
Trabalho . . : Funcao com retorno
Disciplina . : Teoria de Linguagens e Compiladores
Professor . .: Luiz Eduardo da Silva
Aluno . . . .: Maria Luiza Marcelino */

#define TAM_TAB 100
#define MAX_PAR 20
enum {INT, LOG};
//#include <string.h>

struct elemTabSimbolos {
    char id[100];    // identificador
    int end;         // endereço (global) ou deslocamento da variavel local
    int tip;         // tipo
    char cat;        // categoria: função F, parametro P ou variavel V
    char esc;        //escopo global G, local L
    int rot;         //rotulo (especifico para funçao)
    int npar;         //numero de parametros (para função)
    int par[MAX_PAR]; //lista com os tipos de parametros (para funçao)
} tabSimb[TAM_TAB], elemTab;

int posTab = 0;

int desempilha(char);
void empilha (int, char);

int buscaSimbolo(char *id){
    int i;
    //maiuscula(id);
    for (i = posTab - 1; strcmp(tabSimb[i].id, id) && i >= 0; i--);

    if(i == -1)
    {
        char msg[100];
        sprintf(msg, "Identificador [%s] não encontrado!", id);
        yyerror(msg);
    }
 
    return i;
}

//desenvolver uma rotina para ajustar o endereço dos parametros na tabela de simbolos e o vetor de parametros da funçao
//depois que for cadastrado o ultimo parametro 

void ajustaEndereco(int posicao, int numParam){
    int desloc = -3;
    int fimTab = posicao - numParam - 1;
    for (int i = numParam; i > 0; i--){
        posicao--;
        tabSimb[posicao].end = desloc;
        desloc--;
    }
    tabSimb[fimTab].end = desloc;
    tabSimb[fimTab].npar = numParam;
}

int removeVarLocais(){
    int i = posTab - 1; 
    int aux = 0;
    while (tabSimb[i].esc == 'L')
    {
        if(tabSimb[i].cat == 'V'){
            aux++;
        }
        posTab--; //remove da tabela se for escopo L
        i--; //vai andando pra tras pra ver se tem mais o que remover
    }
    return aux;
}


//modificar a rotina mostratabela para representar os outros campos na tabela



void insereSimbolo (struct elemTabSimbolos elem){
    int i;
    //maiuscula(elem.id);
    if(posTab == TAM_TAB)
        yyerror("Tabela de Simbolos Cheia!");
    for (i = posTab - 1; strcmp(tabSimb[i].id,elem.id) && i >= 0; i--);
    //i = buscaSimbolo(elem.id);
    if( i != -1 && tabSimb[i].esc == elem.esc)
    {
        char msg[200];
        sprintf(msg, "Identificador [%s] duplicado!", elem.id);
        yyerror(msg);
    }
       
    tabSimb[posTab++] = elem;

}


void mostraTabela(){
    puts("Tabela de Simbolos");
    puts("------------------");
    printf("\n%30s | %s | %s | %s | %s | %s | %s | %s\n", "ID", "END", "TIP", "ESC", "CAT", "ROT", "NPAR", "PAR");
    for(int i = 0; i < 90; i++)
        printf("-");
    for(int i = 0; i < posTab; i++)
        printf("\n%30s | %3d | %s |  %c  |  %c  | %3d | %3d | ", tabSimb[i].id, tabSimb[i].end, tabSimb[i].tip == INT? "INT" : "LOG", tabSimb[i].esc, tabSimb[i].cat, tabSimb[i].rot, tabSimb[i].npar);
    printf("\n");
}

//e, f, v palavras reservadas
//Estrutura da Pilha Semantica
// usada para enderecos, variaveis, rotulos

/**/
#define TAM_PIL 100
struct{
    int valor;
    char tipo;      //'r' = rotulo, 'n' = nvars, 't' = tipo, 'p' = posicao
} pilha[TAM_PIL];

int topo = -1;

void empilha (int valor, char tipo){
    if(topo == TAM_PIL)
       yyerror("Pilha semântica cheia!");
    pilha[++topo].valor = valor;
    pilha[topo].tipo = tipo;
}

int desempilha(char tipo){
    if (topo == -1)
       yyerror("Pilha semântica vazia!");
    if (pilha[topo].tipo != tipo)
        yyerror("Desempilhamento errado!");
    return pilha[topo--].valor;
}

void testaTipo(int tipo1, int tipo2, int ret){
    int t1 = desempilha('t');
    int t2 = desempilha('t');
    if (t1 != tipo1 || t2 != tipo2)
       yyerror("Incompatibilidade de tipo!");
    empilha(ret, 't');
}
