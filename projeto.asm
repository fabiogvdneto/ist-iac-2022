APAGA_ECRÃ	 		    EQU 6002H   ; endereço do comando para apagar todos os pixels já desenhados
DEFINE_LINHA    		EQU 600AH   ; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH   ; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H   ; endereço do comando para escrever um pixel
APAGA_AVISO     		EQU 6040H   ; endereço do comando para apagar o aviso de nenhum cenário selecionado
SELECIONA_CENARIO_FUNDO EQU 6042H   ; endereço do comando para selecionar uma imagem de fundo
TOCA_SOM				EQU 605AH   ; endereço do comando para tocar um som

MIN_COLUNA              EQU  0      ; número da coluna mais à esquerda que o boneco pode ocupar
MAX_COLUNA		        EQU  63     ; número da coluna mais à direita que o boneco pode ocupar

COR_ROVER               EQU 0E7E4H  ; cor do rover
COR_METEORO             EQU 0E165H  ; cor do meteoro

LARGURA_ROVER           EQU 5       ; largura do rover
ALTURA_ROVER            EQU 2       ; altura do rover

TAMANHO_METEORO         EQU 5       ; tamanho do meteoro

ATRASO                  EQU 400H    ; 1024ms delay

MASCARA					EQU 0FH     ; máscara 0-3 bits


PLACE 1000H
pilha:
    STACK 100H
pilha_inicial:

rover:
    WORD LARGURA_ROVER, ALTURA_ROVER
    WORD 0, 0, COR_ROVER, 0, 0                                  ; linha 1
    WORD COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER  ; linha 2



PLACE 0
    MOV SP, pilha_inicial    ; inicializa SP para a palavra a seguir à última da pilha
    MOV	R1, 0			     ; cenário de fundo número 0

    MOV  [APAGA_AVISO], R1	 ; apaga o aviso de nenhum cenário selecionado (o valor de R1 não é relevante)
    MOV  [APAGA_ECRÃ], R1	 ; apaga todos os pixels já desenhados (o valor de R1 não é relevante)
    MOV  [SELECIONA_CENARIO_FUNDO], R1	; seleciona o cenário de fundo

    MOV R1, 30		; linha inicial
    MOV R2, 29		; coluna inicial
	MOV R4, rover	; tabela que define o boneco
	MOV R11, ATRASO ; atraso em ms que limita a velocidade do rover

    CALL desenha_boneco

ciclo:
	CALL espera_tecla		; espera que uma tecla seja premida e,
							; quando for, guarda a linha em R6 e a coluna em R0
	CALL avalia_tecla
	CALL atraso
	JMP ciclo
	

; ******************************************
; AVALIA_TECLA - Avalia a tecla premida
; Argumentos: R0 - coluna da tecla premida
;             R6 - linha da tecla premida
; ******************************************
avalia_tecla:
	PUSH R7
	PUSH R8
	CALL tecla
	CMP R8, 0
	JZ tecla_0				; se a tecla premida for 0
	CMP R8, 2
	JZ tecla_2				; se a tecla premida for 2
	JMP avalia_tecla_fim	; se a tecla premida não for 0 nem 2
tecla_0:
	MOV R7, -1				; distância a percorrer
	CALL move_horizontal	; move para a esquerda
	JMP avalia_tecla_fim
tecla_2:
	MOV R7, 1				; distância a percorrer
	CALL move_horizontal	; move para a direita
avalia_tecla_fim:
	POP R7
	POP R8
	RET

; ******************************************
; TECLA - Obtém a tecla premida.
; Argumentos: R0 - linha
;             R6 - coluna
; Retorna:    R8 - tecla premida
; ******************************************
tecla:
	MOV R8, 0					; inicializa R10 (será a tecla premida)
tecla_linha_ciclo:
	SHR R0, 1					; avança a linha
	JZ tecla_coluna_ciclo		; se não houver mais linhas, pula para as colunas
	ADD R8, 4					; adiciona 4 ao valor da tecla premida
tecla_coluna_ciclo:
	SHR R6, 1					; avança a coluna
	JZ tecla_fim				; se não houver mais colunas, termina
	ADD R8, 1					; adiciona 1 ao valor da tecla premida
tecla_fim:
	RET

; *********************************************
; MOVE_HORIZONTAL - Move na horizontal (negativo para a esquerda e positivo para a direita)
; Argumentos: R1 - linha
;             R2 - coluna inicial
;             R4 - tabela que define o boneco
;             R7 - distância a percorrer (pode ser negativo)
; *********************************************
move_horizontal:
	PUSH R2
	PUSH R6
	PUSH R7
	MOV R6, [R4]				; obtém largura do boneco
	CALL testa_limites			; testa os limites (força R7 a 0 se chegou ao limite)
	CALL apaga_boneco			; apaga o boneco
	ADD R2, R7					; atualiza coluna
	CALL desenha_boneco			; redesenha o boneco
	POP R7
	POP R6
	POP R2
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
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R1 - linha
;               R2 - coluna
;               R4 - tabela que define o boneco
;
; **********************************************************************
desenha_boneco:
	PUSH R1				; linha
	PUSH R2				; coluna
	PUSH R3				; cor do pixel
	PUSH R4				; tabela
	PUSH R5				; largura
	PUSH R6				; altura
	PUSH R7				; coluna inicial
	PUSH R8				; largura inicial
	MOV R7, R2          ; define a coluna inicial
	MOV R6, [R4]		; obtém a altura
	ADD R4, 2           ; próximo dado na tabela
	MOV	R5, [R4]		; obtém a largura
	ADD	R4, 2			; próximo dado na tabela
desenha_pixels:
	MOV	R3, [R4]		; obtém a cor do pixel
	CALL escreve_pixel	; escreve o pixel usando o R1 (linha), o R2 (coluna) e o R3 (cor)
	ADD	R4, 2			; endereço da cor do próximo pixel (2 porque cada cor de pixel é uma word)
    ADD  R2, 1			; próxima coluna
    SUB  R5, 1			; menos uma coluna para tratar
    JNZ  desenha_pixels	; continua até percorrer toda a largura do boneco

	ADD R1, 1			; próxima linha
	SUB R6, 1			; menos uma linha para tratar
	MOV R2, R7			; redefinir a coluna
	MOV R5, R8          ; redefinir a largura
	JNZ desenha_pixels	; continua até percorrer toda a altura do boneco

	POP R8
	POP R7
	POP R6
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	POP R1
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
	PUSH R1				
	PUSH R2
	PUSH R3
	PUSH R4
	PUSH R5
	PUSH R6
	PUSH R7				; coluna inicial
	PUSH R8				; largura inicial
	MOV R7, R2			; define a coluna inicial
	MOV	R5, [R4]		; obtém a largura do boneco
	MOV R8, R5			; define a largura inicial
	ADD	R4, 2			; próximo dado da tabela
	MOV R6, [R4]		; obtém a altura do boneco
	ADD R4, 2			; próximo dado da tabela
apaga_pixels:
	MOV	R3, 0			; cor para apagar o próximo pixel do boneco
	CALL escreve_pixel	; escreve cada pixel do boneco
	ADD	R4, 2			; próximo dado da tabela
    ADD R2, 1			; próxima coluna
    SUB R5, 1			; menos uma coluna para tratar
    JNZ  apaga_pixels	; continua até percorrer toda a largura do boneco

	MOV R2, R7			; redefine a coluna
	MOV R5, R8			; redefine a largura
	ADD R1, 1			; próxima linha
	SUB R6, 1			; menos uma linha para tratar
	JNZ  apaga_pixels	; continua até percorrer toda a altura do boneco

	POP R8
	POP R7
	POP R6
	POP	R5
	POP	R4
	POP	R3
	POP	R2
	POP R1
	RET




; **********************************************************************
; ATRASO - Executa um ciclo para implementar um atraso.
; Argumentos:   R11 - valor que define o atraso
;
; **********************************************************************
atraso:
	PUSH R11
ciclo_atraso:
	SUB	R11, 1
	JNZ	ciclo_atraso
	POP	R11
	RET

; **********************************************************************
; TESTA_LIMITES - Testa se o boneco chegou aos limites do ecrã e nesse caso
;			   impede o movimento (força R7 a 0)
; Argumentos:	R2 - coluna em que o boneco
 está
;			    R6 - largura do boneco
;			    R7 - sentido de movimento do boneco (valor a somar à coluna
;				     em cada movimento: +1 para a direita, -1 para a esquerda)
;
; Retorna: 	    R7 - 0 se já tiver chegado ao limite, inalterado caso contrário	
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
; ESPERA_TECLA - Espera ate a tecla parar de ser premida.
; Retorna: R6 - valor lido das linhas do teclado (0, 1, 2, 4 ou 8)
;          R0 - valor lido das colunas do teclado (0, 1, 2, 4 ou 8)
; *****************************************************
espera_tecla:
    CALL testa_linhas	; testa linhass
    CMP R0, 0
    JZ espera_tecla		; se ainda nenhuma tecla foi premida, repete
    RET

; *****************************************************
; HA_TECLA - Espera ate a tecla parar de ser premida.
; Argumentos: R6 - linha a testar (1, 2, 4, 8)
; *****************************************************
ha_tecla:
    PUSH R0
ha_tecla_ciclo:
    CALL testa_linha		; testa a linha em R6
    CMP R0, 0
    JNZ ha_tecla_ciclo		; se ainda houver uma tecla premida, repete
ha_tecla_fim:
    POP R0
    RET

; ******************************************************
; TESTA_LINHAS - Faz uma leitura às linhas e retorna a linha e a coluna da tecla premida
; Retorna: R6 - linha da tecla premida (1, 2, 4 ou 8), ou 0
;          R0 - coluna da tecla premida (1, 2, 4 ou 8), ou 0
; ******************************************************
testa_linhas:
    MOV R6, 8				; testa quarta linha
testa_linhas_loop:
    CALL testa_linha		; testa a linha em R6
    CMP R0, 0				; verifica se alguma tecla foi premida na linha R6
    JNZ teclado_fim			; se alguma tecla tiver sido premida, retorna
linha_seguinte:
    SHR R6, 1				; linha seguinte
    CMP R6, 0				; se R6 for 0, não há mais linhas para testar
    JNZ testa_linhas_loop	; testa a linha, se existir
teclado_fim:
    RET

; **********************************************************************
; TESTA_LINHA - Faz uma leitura a uma linha do teclado e retorna a coluna da tecla premida
; Argumentos: R6 - linha a testar (1, 2, 4 ou 8)
; Retorna: 	  R0 - coluna da tecla premida (1, 2, 4, ou 8), ou 0	
; **********************************************************************
testa_linha:
	PUSH	R2
	PUSH	R3
	PUSH	R5
	MOV  R2, TEC_LIN	; endereço do periférico das linhas
	MOV  R3, TEC_COL	; endereço do periférico das colunas
	MOV  R5, MASCARA	; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOVB [R2], R6		; escrever no periférico de saída (linhas)
	MOVB R0, [R3]		; ler do periférico de entrada (colunas)
	AND  R0, R5			; elimina bits para além dos bits 0-3
	POP	R5
	POP	R3
	POP	R2
	RET
