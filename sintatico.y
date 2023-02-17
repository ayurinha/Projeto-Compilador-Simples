/* UNIFAL = Universida de Federal de Alfenas.
BACHARELADO EM CIENCIA DA COMPUTACAO.
Trabalho . . : Funcao com retorno
Disciplina . : Teoria de Linguagens e Compiladores
Professor . .: Luiz Eduardo da Silva
Aluno . . . .: Maria Luiza Marcelino */

%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lexico.c"
#include "utils.c"
#define MAX_PAR 20
int contaVar;  //conta numero de variaveis
int contaLocal = 0;
int rotulo = 0; //marca lugares no codigo
int tipo;
char escopo = 'G';
char categoria;
int endereco = 0;
int numParametros = 0;
int listaPar[MAX_PAR];
int contaEndereco = 0;
int variavelAuxiliar = 0;
int varAux = 0;
int numArgs = 0;
%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_ENQTO
%token T_FACA
%token T_FIMENQTO
%token T_INTEIRO
%token T_LOGICO
%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV
%token T_ATRIBUI
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E
%token T_OU
%token T_NAO
%token T_ABRE
%token T_FECHA
%token T_V
%token T_F
%token T_IDENTIF
%token T_NUMERO

/*adicionar os tokens retorne, func e fimfunc*/
%token T_FUNC
%token T_RETORNE
%token T_FIMFUNC

%start programa
%expect 1

%left T_E T_OU
%left T_IGUAL
%left T_MAIOR T_MENOR
%left T_MAIS T_MENOS
%left T_VEZES T_DIV

%%

programa 
    : cabecalho 
        {contaVar = 0;}
      variaveis 
        { 
            mostraTabela();
            if (contaVar){
                fprintf(yyout,"\tAMEM\t%d\n", contaVar);    //imprime AMEM
            }
            empilha(contaVar, 'n');     //conta variaveis
        }
        rotinas 
     T_INICIO lista_comandos T_FIM
        { 
            //int conta = desempilha('n');
            mostraTabela();
            if (contaVar > 0)
               fprintf(yyout,"\tDMEM\t%d\n", contaVar); 
            fprintf(yyout, "\tFIMP\n");    
        }
    ;

cabecalho
    : T_PROGRAMA T_IDENTIF
        {fprintf(yyout,"\tINPP\n"); }
    ;

variaveis
    : /* vazio */
    | declaracao_variaveis
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo
   : T_LOGICO
     { tipo = LOG; }
   | T_INTEIRO
    { tipo = INT; }
   ;

lista_variaveis
    : lista_variaveis  T_IDENTIF 
        { 
            strcpy(elemTab.id, atomo);
            if (escopo == 'L'){
                elemTab.end = contaLocal;
                contaLocal++;
            }else{
                elemTab.end = contaVar;
                contaVar++;
            }
            elemTab.tip = tipo;
            elemTab.cat = 'V';
            elemTab.esc = escopo;
            //elemTab.par = NULL;
            insereSimbolo(elemTab);
            contaEndereco++;
        }
    | T_IDENTIF
        { 
           strcpy(elemTab.id, atomo);
           if (escopo == 'L'){
                elemTab.end = contaLocal;
                contaLocal++;
            }else{
                elemTab.end = contaVar;
                contaVar++;
            }
           elemTab.tip = tipo;
           elemTab.esc = escopo;
           elemTab.cat = 'V';
           insereSimbolo(elemTab); 
           contaEndereco++;  
        }
    ;

rotinas
    : /*não tem funcoes*/
    | 
        {
            fprintf (yyout,"\tDSVS\tL%d\n", rotulo);
            empilha(rotulo, 'r');
        }
    funcoes
        { 
            int r = desempilha('r');
            fprintf(yyout, "L%d\tNADA\n", r);
        }
    ;

funcoes
    : funcao
    | funcao funcoes
    ;

funcao
    : T_FUNC tipo T_IDENTIF { 

            varAux = contaEndereco;
            strcpy(elemTab.id, atomo);
            elemTab.tip = tipo;
            elemTab.cat = 'F';
            elemTab.rot = ++rotulo;
            elemTab.esc = escopo;
            elemTab.end = contaEndereco;
            //elemTab.npar = numParametros;
            //elemTab.par = NULL;
            insereSimbolo(elemTab);
            fprintf(yyout, "L%d\tENSP\n", rotulo);
            escopo = 'L';
            contaEndereco++;
    }
    T_ABRE parametros T_FECHA
    {
        
       /* cria rotina para ajustar parametros 
        para cada simbolo que for paramentro diminuir o deslocamento até chegar na cat F que é a funçao trata isso em outro lugar int desloc = (numParametros * -1)+deslocamento;*/
       ajustaEndereco(contaEndereco, numParametros);
       //mostraTabela();
       

    }
    variaveis {
        if (contaLocal > 0){
                fprintf(yyout,"\tAMEM\t%d\n", contaLocal);    //imprime AMEM
            }
    } T_INICIO lista_comandos T_FIMFUNC
    {
        /*{//remover_variaveis_l-cat() remover variaveis locais e gerar DMEN zerar elemTab.par[]
        }*/
        int varRemovidas = removeVarLocais();
        //contaVar = contaVar - varRemovidas; //tira as variaveis removidas da contagem geral de variaveis
        //mostraTabela();
        contaLocal = 0;
        escopo = 'G'; //volta o escopo pra global
        numParametros = 0; //volta a quantidade de parametros pra zero
        
    }
    ;


parametros
    : /*vazio*/
    | parametro parametros
    ;

parametro
    : tipo T_IDENTIF 
        {
            listaPar[numParametros] = tipo;
            numParametros++;
            strcpy(elemTab.id, atomo);
            elemTab.tip = tipo;
            elemTab.cat = 'P';
            elemTab.rot = 0;
            elemTab.end = contaEndereco;
            elemTab.esc = escopo;
            insereSimbolo(elemTab);
            contaEndereco++;
        }
    ;

lista_comandos
    : /* vazia */
    | comando lista_comandos
    ;

comando
    : entrada_saida
    | repeticao
    | selecao
    | atribuicao
    | retorno
    ;

/*comando retorno só faz sentido dentro da função*/
/* tem que gerar os codigos ARZL (valor de retorno) > DMEN (se tiver variavel local) > RTSP (retorno de sub programa)*/
retorno 
    : T_RETORNE expressao
    {
        //mostraTabela();
        int t1 = desempilha('t');
        /* if (t1 != tabSimb[varAux].tip){
            yyerror("Retorno com tipo errado");
        }*/
        if(escopo != 'L')
            yyerror("Escopo errado!");


        fprintf(yyout,"\tARZL\t%d\n", tabSimb[varAux].end);
        if(contaLocal > 0){
            fprintf(yyout,"\tDMEN\t%d\n", contaLocal);
        }

        fprintf(yyout,"\tRTSP\t%d\n", tabSimb[varAux].npar);
        
    }
    ;

entrada_saida
    : leitura
    | escrita
    ;

leitura
    : T_LEIA T_IDENTIF
        { 
            int pos = buscaSimbolo(atomo);
            fprintf(yyout,"\tLEIA\n\tARZG\t%d\n", tabSimb[pos].end); 
        }
    ;

escrita 
    : T_ESCREVA expressao
         { 
            desempilha('t');
            fprintf(yyout,"\tESCR\n"); 
         }
    ;

repeticao
    : T_ENQTO 
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo); 
            empilha(rotulo, 'r');
        }
      expressao T_FACA 
        {
             int tip = desempilha('t');
             printf("O que desempilho aqui: %d", LOG);
             if(tip != LOG)
                 yyerror("Incompatilidade de tipo");
             fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
             empilha(rotulo, 'r');
        }
      lista_comandos 
      T_FIMENQTO
         { 
            int rot1 = desempilha('r');
            int rot2 = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\n",rot2);
            fprintf(yyout,"L%d\tNADA\n",rot1);
         }
    ;

selecao
    : T_SE expressao T_ENTAO 
        {
             int tip = desempilha('t');
             if(tip != LOG)
                 yyerror("Incompatilidade de tipo!");
             fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
             empilha(rotulo, 'r');
        }
      lista_comandos T_SENAO 
        { 
            int rot = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\n", ++rotulo);
            fprintf(yyout,"L%d\tNADA\n", rot);
            empilha(rotulo, 'r');
        }
      lista_comandos T_FIMSE
        { 
            int rot = desempilha('r');
            fprintf(yyout,"L%d\tNADA\n", rot); 
        }
    ;

atribuicao
    : T_IDENTIF 
        {
            int pos = buscaSimbolo(atomo);
            empilha(pos, 'p');
        }   
      T_ATRIBUI expressao
        {
            int tip = desempilha('t');
            int pos = desempilha('p');
            if (tabSimb[pos].tip != tip)
               yyerror("Incompatibilidade de tipo!");
             
            if(tabSimb[pos].esc == 'L'){
                fprintf(yyout,"\tARZL\t%d\n", tabSimb[pos].end);
            } else if(tabSimb[pos].esc == 'G') {
                fprintf(yyout,"\tARZG\t%d\n", tabSimb[pos].end);
            }
        }
    ;

expressao
    : expressao T_VEZES expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tMULT\n"); 
        }
    | expressao T_DIV expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tDIVI\n"); 
        }
    | expressao T_MAIS expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tSOMA\n"); 
        }
    | expressao T_MENOS expressao
        {
            testaTipo(INT,INT, INT);
            fprintf(yyout,"\tSUBT\n");
        }
    | expressao T_MAIOR expressao
        {
            testaTipo(INT,INT, LOG);
            fprintf(yyout,"\tCMMA\n"); 
        }
    | expressao T_MENOR expressao
        {
            testaTipo(INT,INT, LOG);
            fprintf(yyout,"\tCMME\n");
        }
    | expressao T_IGUAL expressao
        {
            testaTipo(INT,INT, LOG);
            fprintf(yyout,"\tCMIG\n"); 
        }
    | expressao T_E expressao 
        {
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tCONJ\n"); 
        }
    | expressao T_OU expressao
        {
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tDISJ\n"); 
        }
    | termo
    ;

chamada
    : {
        int pos = desempilha('p');
        if(tabSimb[pos].esc == 'L'){
            fprintf(yyout,"\tCRVL\t%d\n", tabSimb[pos].end);
        } else if(tabSimb[pos].esc == 'G') {
            fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].end);
        }
        empilha(tabSimb[pos].tip, 't');
    }
    | T_ABRE {
        int pos = desempilha('p');
        if (pos == -1){
            yyerror("Função não declarada!");
        }
        variavelAuxiliar = pos;
        //mostraTabela();
        empilha(tabSimb[pos].tip, 't');
        fprintf(yyout,"\tAMEM\t%d\n", 1);
    } 
    lista_argumentos T_FECHA  {
        
        //mostraTabela();
         if (numArgs != tabSimb[variavelAuxiliar].npar){
            yyerror("Argumentos diferentes de parametros!");
        }

        fprintf(yyout,"\tSVCP\n");
        fprintf(yyout,"\tDSVS\tL%d\n", tabSimb[variavelAuxiliar].rot);
        numArgs = 0;
    }
    ;

identificador
    : T_IDENTIF
        {
            int pos = buscaSimbolo(atomo); 
             if(pos == -1){
                yyerror("Variavel nao declarada!");
             }
            empilha(pos, 'p'); 
        }
    ;

lista_argumentos
    : 
    | argumentos 
    ;

argumentos 
    : argumentos argumento
    | argumento
    ;

argumento
    : expressao {
        numArgs++;
        //mostraTabela();
        int i = desempilha('t');
        //printf("O que desempilho aqui:  %d", tabSimb[variavelAuxiliar].end);
        int j = tabSimb[variavelAuxiliar].npar;
        
        int k = 1;
        for( j > 0; j--;){

            //printf("Arg: %d  Param: %d \t", numArgs, tabSimb[variavelAuxiliar+k].end);
            
            if(i != tabSimb[variavelAuxiliar+k].tip){
                yyerror("Tipo diferente de argumento! ");
            }
            k++;
        }
        //empilha(i, 't');
    }
    ;

termo
    : identificador chamada
    | T_NUMERO
        {
        fprintf(yyout,"\tCRCT\t%s\n", atomo);
        empilha(INT, 't');
        }
    | T_V
        {
        fprintf(yyout,"\tCRCT\t1\n"); 
        empilha(LOG, 't');
        }
    | T_F
        {
        fprintf(yyout,"\tCRCT\t0\n"); 
        empilha(LOG, 't');
        }
    | T_NAO termo
        {
        int t = desempilha('t');
        if (t != LOG) yyerror ("Incompatibilidade de tipo!");
        fprintf(yyout,"\tNEGA\n"); 
        empilha(LOG, 't');
        }
    | T_ABRE expressao T_FECHA
    ;
%%



int main(int argc, char *argv[]){
    char *p, nameIn[100], nameOut[100];
    argv++;
    if(argc < 2){
        puts("\nCompilador Simples\n");
        puts("\n\tUso: ./simples <NOME>[.simples]/n/n");
        exit(10);
    }
    p = strstr(argv[0], ".simples");
    if(p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen(nameIn, "rt");
    if(!yyin){
        puts("Programa fonte não encontrado!");
        exit(20);
    }
    yyout = fopen(nameOut,"wt");
    yyparse(); /*LR melhorado*/
    puts("Programa ok!");
}