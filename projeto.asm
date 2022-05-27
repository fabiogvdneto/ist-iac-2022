APAGA_ECRÃ	 		    EQU 6002H   ; endereço do comando para apagar todos os pixels já desenhados
DEFINE_LINHA    		EQU 600AH   ; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH   ; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H   ; endereço do comando para escrever um pixel
APAGA_AVISO     		EQU 6040H   ; endereço do comando para apagar o aviso de nenhum cenário selecionado
SELECIONA_CENARIO_FUNDO EQU 6042H   ; endereço do comando para selecionar uma imagem de fundo
TOCA_SOM				EQU 605AH   ; endereço do comando para tocar um som

MIN_COLUNA              EQU  0      ; número da coluna mais à esquerda que o objeto pode ocupar
MAX_COLUNA		        EQU  63     ; número da coluna mais à direita que o objeto pode ocupar

COR_ROVER               EQU 0E7E4H  ; cor do rover
COR_METEORO             EQU 0E165H  ; cor do meteoro

LARGURA_ROVER           EQU 5       ; largura do rover
ALTURA_ROVER            EQU 2       ; altura do rover

TAMANHO_METEORO         EQU 5       ; tamanho do meteoro

ATRASO                  EQU 400H    ; 1024ms delay


PLACE 1000H
pilha:
    STACK 100H
pilha_inicial:

rover:
    WORD ALTURA_ROVER, LARGURA_ROVER
    WORD 0, 0, COR_ROVER, 0, 0                                  ; linha 1
    WORD COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER  ; linha 2



PLACE 0
    MOV SP, pilha_inicial    ; inicializa SP para a palavra a seguir à última da pilha
    MOV	R1, 0			     ; cenário de fundo número 0

    MOV  [APAGA_AVISO], R1	 ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV  [APAGA_ECRÃ], R1	 ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
    MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo

    MOV R1,
    MOV R2,

    CALL DESENHA_BONECO





; **********************************************************************
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o boneco
;
; **********************************************************************
desenha_boneco:
	PUSH R2 ; coluna
	PUSH R3 ; cor do pixel currente
	PUSH R4 ; 
	PUSH R5
	PUSH R6
	MOV R6, [R4]        ; obtém a altura do boneco
	ADD R4, 2           
	MOV	R5, [R4]			; obtém a largura do boneco
	ADD	R4, 2			; endereço da cor do 1º pixel (2 porque a largura é uma word)
desenha_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV	R3, [R4]			; obtém a cor do próximo pixel do boneco
	CALL	escreve_pixel		; escreve cada pixel do boneco
	ADD	R4, 2			; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1               ; próxima coluna
    SUB  R5, 1			; menos uma coluna para tratar
    JNZ  desenha_pixels      ; continua até percorrer toda a largura do objeto
	ADD R1, 1
	SUB R6, 1
	POP R6
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	RET

; **********************************************************************
; APAGA_BONECO - Apaga um boneco na linha e coluna indicadas
;			  com a forma definida na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o boneco
;
; **********************************************************************
apaga_boneco:
	PUSH	R2
	PUSH	R3
	PUSH	R4
	PUSH	R5
	MOV	R5, [R4]			; obtém a largura do boneco
	ADD	R4, 2			; endereço da cor do 1º pixel (2 porque a largura é uma word)
apaga_pixels:       		; desenha os pixels do boneco a partir da tabela
	MOV	R3, 0			; cor para apagar o próximo pixel do boneco
	CALL	escreve_pixel		; escreve cada pixel do boneco
	ADD	R4, 2			; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1               ; próxima coluna
    SUB  R5, 1			; menos uma coluna para tratar
    JNZ  apaga_pixels      ; continua até percorrer toda a largura do objeto
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	RET


; **********************************************************************
; ESCREVE_PIXEL - Escreve um pixel na linha e coluna indicadas.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R3 - cor do pixel (em formato ARGB de 16 bits)
;
; **********************************************************************
escreve_pixel:
	MOV  [DEFINE_LINHA], R1		; seleciona a linha
	MOV  [DEFINE_COLUNA], R2		; seleciona a coluna
	MOV  [DEFINE_PIXEL], R3		; altera a cor do pixel na linha e coluna já selecionadas
	RET


; **********************************************************************
; ATRASO - Executa um ciclo para implementar um atraso.
; Argumentos:   R11 - valor que define o atraso
;
; **********************************************************************
atraso:
	PUSH	R11
ciclo_atraso:
	SUB	R11, 1
	JNZ	ciclo_atraso
	POP	R11
	RET

; **********************************************************************
; TESTA_LIMITES - Testa se o boneco chegou aos limites do ecrã e nesse caso
;			   impede o movimento (força R7 a 0)
; Argumentos:	R2 - coluna em que o objeto está
;			R6 - largura do boneco
;			R7 - sentido de movimento do boneco (valor a somar à coluna
;				em cada movimento: +1 para a direita, -1 para a esquerda)
;
; Retorna: 	R7 - 0 se já tiver chegado ao limite, inalterado caso contrário	
; **********************************************************************
testa_limites:
	PUSH	R5
	PUSH	R6
testa_limite_esquerdo:		; vê se o boneco chegou ao limite esquerdo
	MOV	R5, MIN_COLUNA
	CMP	R2, R5
	JGT	testa_limite_direito
	CMP	R7, 0			; passa a deslocar-se para a direita
	JGE	sai_testa_limites
	JMP	impede_movimento	; entre limites. Mantém o valor do R7
testa_limite_direito:		; vê se o boneco chegou ao limite direito
	ADD	R6, R2			; posição a seguir ao extremo direito do boneco
	MOV	R5, MAX_COLUNA
	CMP	R6, R5
	JLE	sai_testa_limites	; entre limites. Mantém o valor do R7
	CMP	R7, 0			; passa a deslocar-se para a direita
	JGT	impede_movimento
	JMP	sai_testa_limites
impede_movimento:
	MOV	R7, 0			; impede o movimento, forçando R7 a 0
sai_testa_limites:	
	POP	R6
	POP	R5
	RET

; *****************************************************
; HA_TECLA - Espera ate a tecla parar de ser premida.
; Argumentos: R6 - linha a testar (1, 2, 4, 8)
; *****************************************************
enquanto_ha_tecla:
    PUSH R0
enquanto_ha_tecla_ciclo:
    CALL linha
    CMP R0, 0
    JNZ enquanto_ha_tecla_ciclo
enquanto_ha_tecla_fim:
    POP R0
    RET

; ******************************************************
; TECLADO - Faz uma leitura às teclas do teclado e retorna o valor lido
; Retorna: R6 - valor lido das linhas do teclado (0, 1, 2, 4 ou 8)
;          R0 - valor lido das colunas do teclado (0, 1, 2, 4 ou 8)
; ******************************************************
teclado:
    MOV R6, 8              ; testa quarta linha
testa_linha:
    CALL linha             ; testa a linha em R6
    CMP R0, 0              ; verifica se alguma tecla foi premida na linha R6
    JZ linha_seguinte      ; se nenhuma tecla foi premida, testa a linha seguinte
linha_seguinte:
    SHR R6, 1              ; muda para a linha seguinte
    CMP R6, 0              ; verifica se já não há mais linhas para testar
    JZ teclado_fim         ; se não houver mais linhas, termina
    JMP testa_linha        ; se houver, testa a linha
teclado_fim:
    RET

; **********************************************************************
; TECLA - Faz uma leitura às teclas de uma linha do teclado e retorna o valor lido
; Argumentos:	R6 - linha a testar (em formato 1, 2, 4 ou 8)
;
; Retorna: 	R0 - valor lido das colunas do teclado (0, 1, 2, 4, ou 8)	
; **********************************************************************
linha:
	PUSH	R2
	PUSH	R3
	PUSH	R5
	MOV  R2, TEC_LIN   ; endereço do periférico das linhas
	MOV  R3, TEC_COL   ; endereço do periférico das colunas
	MOV  R5, MASCARA   ; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOVB [R2], R6      ; escrever no periférico de saída (linhas)
	MOVB R0, [R3]      ; ler do periférico de entrada (colunas)
	AND  R0, R5        ; elimina bits para além dos bits 0-3
	POP	R5
	POP	R3
	POP	R2
	RET
