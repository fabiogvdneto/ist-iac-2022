APAGA_ECRÃ	 		    EQU 6002H	; endereço do comando para apagar todos os pixels já desenhados
DEFINE_LINHA    		EQU 600AH	; endereço do comando para definir a linha
DEFINE_COLUNA   		EQU 600CH	; endereço do comando para definir a coluna
DEFINE_PIXEL    		EQU 6012H	; endereço do comando para escrever um pixel
APAGA_AVISO     		EQU 6040H	; endereço do comando para apagar o aviso de nenhum cenário selecionado
SELECIONA_CENARIO_FUNDO EQU 6042H	; endereço do comando para selecionar uma imagem de fundo
TOCA_SOM				EQU 605AH	; endereço do comando para tocar um som

DISPLAY					EQU 0A000H	; enderço do POUT-1 ligado a 3 displays
TEC_LIN					EQU 0C000H	; endereço do POUT-2 que liga às linhas do teclado
TEC_COL					EQU 0E000H	; endereço do PIN que liga às colunas do teclado

MIN_COLUNA              EQU 0		; número da coluna mais à esquerda que o boneco pode ocupar
MAX_COLUNA		        EQU 63		; número da coluna mais à direita que o boneco pode ocupar

COR_ROVER               EQU 0FDD7H	; cor do rover RGB
LARGURA_ROVER           EQU 5		; largura do rover
ALTURA_ROVER            EQU 2		; altura do rover
LINHA_ROVER				EQU 30		; linha do rover

COR_MET_BOM             EQU 0F0E2H  ; cor do meteoro bom
TAMANHO_MET_BOM         EQU 5       ; tamanho do meteoro bom
COLUNA_MET_BOM			EQU 30		; coluna do meteoro bom

ATRASO                  EQU 0C000H	; atraso aplicado à movimentação do rover
MASCARA					EQU 000FH	; máscara 0-3 bits


PLACE 1000H
pilha:
    STACK 100H
pilha_inicial:

rover:
    WORD LARGURA_ROVER, ALTURA_ROVER
    WORD 0, 0, COR_ROVER, 0, 0
    WORD COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER, COR_ROVER

meteoro_bom:
    WORD TAMANHO_MET_BOM, TAMANHO_MET_BOM
    WORD 0, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, 0
    WORD COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM
    WORD COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM
    WORD COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM
    WORD 0, COR_MET_BOM, COR_MET_BOM, COR_MET_BOM, 0

PLACE 0
    MOV SP, pilha_inicial				; inicializa SP para a palavra a seguir à última da pilha
    MOV	R0, 0							; valor do display
	MOV [DISPLAY], R0					; reinicia o valor no display
    MOV [APAGA_AVISO], R0				; apaga o aviso de nenhum cenário selecionado (o valor de R0 não é relevante)
    MOV [APAGA_ECRÃ], R0				; apaga todos os pixels já desenhados (o valor de R0 não é relevante)
    MOV [SELECIONA_CENARIO_FUNDO], R0	; seleciona o cenário de fundo (aproveita-se o valor de R0)

    MOV R1, 30		; coluna inicial do rover
	MOV R2, 0		; linha do meteoro bom

    MOV R11, LINHA_ROVER	; linha de referência do rover
    MOV R10, R1     		; coluna de referência do rover
	MOV R8, rover			; tabela que define o rover
    CALL desenha_boneco		; desenha o rover

	MOV R11, R2				; linha de referência do meteoro bom
	MOV R10, COLUNA_MET_BOM	; coluna de referência do meteoro bom
	MOV R8, meteoro_bom		; tabela que define o meteoro bom
	CALL desenha_boneco		; desenha o meteoro bom
ciclo:
	CALL espera_tecla		; espera que uma tecla seja premida e,
							; quando for, retorna a linha (R11) e a coluna (R10)
	CALL tecla				; obtém o valor da tecla premida (R9)
	CMP R9, 0				; se a tecla premida for 0
	JZ tecla_0				; move o rover para a esquerda
	CMP R9, 1				; se a tecla premida for 1
	JZ tecla_1				; desce o meteoro
	CMP R9, 2				; se a tecla premida for 2
	JZ tecla_2				; move o rover para a direita
	CMP R9, 3				; se a tecla premida for 3
    JZ tecla_3				; aumenta o valor no display
    CMP R9, 7				; se a tecla premida for 7
    JZ tecla_7				; diminui o valor no display
	JMP ciclo
tecla_0:
    MOV R11, LINHA_ROVER	; linha de referência do rover
    MOV R10, R1				; coluna de referência do rover
	MOV R8, rover			; tabela que define o rover
	MOV R7, -1				; distância a percorrer
	CALL move_horizontal	; move para a esquerda
    MOV R1, R10             ; atualiza a coluna
	MOV R11, ATRASO         ; valor que define o atraso
	CALL atraso             ; aplica o atraso
	JMP ciclo
tecla_1:
	CALL ha_tecla
	MOV R11, 0				; número do som
	MOV [TOCA_SOM], R11		; toca o primeiro som (meteoro a cair)
	MOV R11, R2				; linha de referência do meteoro bom
	MOV R10, COLUNA_MET_BOM	; coluna de referência do meteoro bom
	MOV R8, meteoro_bom		; tabela que define o meteoro bom
	CALL apaga_boneco		; apaga o meteoro na posição antiga
	ADD R11, 1				; atualiza a linha de referência do meteoro
	CALL desenha_boneco		; redesenha o meteoro na posição atualizada
	MOV R2, R11				; atualiza a linha de referência do meteoro permanentemente
	JMP ciclo
tecla_2:
    MOV R11, LINHA_ROVER	; linha atual do rover
    MOV R10, R1				; coluna atual do rover
	MOV R8, rover			; tabela que define o rover
	MOV R7, 1				; distância a percorrer
	CALL move_horizontal	; move para a direita
    MOV R1, R10             ; atualiza a coluna
	MOV R11, ATRASO         ; valor que define o atraso
	CALL atraso             ; aplica o atraso
    JMP ciclo
tecla_3:
    CALL ha_tecla			; aguarda que a tecla pare de ser premida
	MOV R11, R0				; copia o valor do display para R11
	CALL incrementa_decimal	; incrementa o valor em R11
	MOV R0, R11				; atualiza o valor do display
    MOV [DISPLAY], R0		; escreve o valor atualizado no display
    JMP ciclo
tecla_7:
    CALL ha_tecla
    CMP R0, 0				; vê se o valor no display é zero para evitar números negativos
    JZ ciclo				; o valor mostrado no display não pode ser negativo
    MOV R11, R0				; copia o valor do display para R11
	CALL decrementa_decimal	; decrementa o valor em R11
	MOV R0, R11				; atualiza o valor do display
	MOV [DISPLAY], R0		; escreve o valor atualizado no display
    JMP ciclo

; *******************************************************
; INCREMENTA_DECIMAL - Incrementa em 1 o valor em decimal
; Argumentos: R11 - o valor por incrementar
; Retorna:    R11 - o valor atualizado
; *******************************************************
incrementa_decimal:
	PUSH R0
	PUSH R1
	PUSH R2
	MOV R0, MASCARA				; máscara de 1 byte (começa nos 0-3 bits)
	MOV R1, 1					; multiplicador
incrementa_decimal_ciclo:
	MOV R2, R11					; cópia do valor
	AND R2, R0					; filtra o primeiro byte
	ADD R2, -8					; se o dígito for inferior a 9
	JLE incrementa_decimal_fim	; termina (podemos incrementar o valor)
	SHR R11, 4					; evidencia o próximo byte
	SHL R1, 4					; shift left de 1 byte ao valor a multiplicar
	JMP incrementa_decimal_ciclo
incrementa_decimal_fim:
	ADD R11, 1
	MUL R11, R1		; restaura os bytes anteriores de R11 que sofreram shift
	POP R2
	POP R1
	POP R0
	RET

; *******************************************************
; DECREMENTA_DECIMAL - Incrementa em 1 o valor em decimal
; Argumentos: R11 - o valor por decrementar
; Retorna:    R11 - o valor atualizado
; *******************************************************
decrementa_decimal:
	PUSH R0
	PUSH R1
	PUSH R2
	MOV R0, MASCARA				; máscara de 1 byte (começa nos 0-3 bits)
	MOV R1, 6					; valor a subtrair (F - 6 = 9)
	SUB R11, 1					; decrementa o valor (os F serão substituídos no ciclo que se segue)
decrementa_decimal_ciclo:
	MOV R2, R11					; cópia do valor
	AND R2, R0					; filtra o byte seguinte
	CMP R2, R0					; se o dígito não for F (aproveita-se o valor da máscara)
	JNZ decrementa_decimal_fim	; termina
	SUB R11, R1					; subtrai 6 ao byte evidenciado
	SHL R0, 4					; evidencia o próximo byte
	SHL R1, 4					; move o valor a subtrair para o próximo byte
	JMP decrementa_decimal_ciclo
decrementa_decimal_fim:
	POP R2
	POP R1
	POP R0
	RET

; *********************************************
; MOVE_HORIZONTAL - Move na horizontal (negativo para a esquerda e positivo para a direita)
; Argumentos: R11 - linha
;             R10 - coluna inicial
;             R8 - tabela que define o boneco
;             R7 - distância a percorrer (pode ser negativo)
; Retorna:    R10 - coluna atualizada
;             R7 - distância percorrida (0 se chegou ao limite, inalterada caso contrário)
; *********************************************
move_horizontal:
    PUSH R6
	MOV R6, [R8]				; obtém largura do boneco
	CALL testa_limites			; testa os limites (força R7 a 0 se chegou ao limite)
	CALL apaga_boneco			; apaga o boneco
	ADD R10, R7					; atualiza coluna
	CALL desenha_boneco			; redesenha o boneco
	POP R6
	RET

; ************************************************************************
; TESTA_LIMITES - Testa se o boneco chegou aos limites do ecrã e nesse caso
;			   impede o movimento (força R7 a 0)
; Argumentos:	R10 - coluna em que o boneco está
;			    R7 - sentido de movimento do boneco (valor a somar à coluna
;				     em cada movimento: +1 para a direita, -1 para a esquerda)
;               R6 - largura do boneco
; Retorna: 	    R7 - 0 se já tiver chegado ao limite, inalterado caso contrário	
; ************************************************************************
testa_limites:
	PUSH R0
	PUSH R6
	CMP R7, 0                   ; se o movimento for para a direita (R7 > 0)
	JGE testa_limite_direito	; testa para a direita (caso contrário testa para a esquerda)
testa_limite_esquerdo:
	MOV R0, MIN_COLUNA
	CMP R10, R0                 ; se o pixel de referência do boneco não estiver na coluna mínima
	JNZ testa_limites_fim		; não impede o movimento
	JMP impede_movimento		; caso contrário, impede o movimento
testa_limite_direito:
	MOV R0, MAX_COLUNA
	ADD R6, R10                 ; calcula o pixel mais à direita do boneco
	SUB R6, 1					; calcula o pixel mais à direita do boneco
	CMP R6, R0                  ; se o pixel mais à direita do boneco não estiver na coluna máxima
	JNZ testa_limites_fim		; não impede o movimento (caso contrário, impede o movimento)
impede_movimento:
	MOV R7, 0					; impede o movimento forçando R7 a 0
testa_limites_fim:
	POP R6
	POP R0
	RET

; **********************************************************************
; DESENHA_BONECO - Desenha um boneco na linha e coluna indicadas
;			    com a forma e cor definidas na tabela indicada.
; Argumentos:   R11 - linha
;               R10 - coluna
;               R8 - tabela que define o boneco
;
; **********************************************************************
desenha_boneco:
	PUSH R11
	PUSH R10
	PUSH R9
    PUSH R8
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	MOV R0, [R8]		; obtém a largura
	ADD R8, 2			; próximo dado na tabela
	MOV R1, [R8]		; obtém a altura
	MOV R2, R10         ; define a coluna inicial
	MOV R3, R0			; define a largura inicial
desenha_pixels:
	ADD R8, 2	    	; próximo dado na tabela
	MOV	R9, [R8]		; obtém a cor do pixel
	CALL escreve_pixel	; escreve o pixel usando o R1 (linha), o R2 (coluna) e o R3 (cor)
    ADD R10, 1			; próxima coluna
    SUB R0, 1			; menos uma coluna para tratar
    JNZ desenha_pixels	; continua até percorrer toda a largura do boneco
	MOV R10, R2			; redefinir a coluna
	MOV R0, R3          ; redefinir a largura
	ADD R11, 1			; próxima linha
	SUB R1, 1			; menos uma linha para tratar
	JNZ desenha_pixels	; continua até percorrer toda a altura do boneco
	POP R3
	POP R2
	POP R1
	POP	R0
	POP	R8
    POP R9
	POP	R10
	POP R11
	RET

; **********************************************************************
; APAGA_BONECO - Apaga um boneco na linha e coluna indicadas
;			  com a forma definida na tabela indicada.
; Argumentos:   R11 - linha
;               R10 - coluna
;               R8 - tabela que define o boneco
; **********************************************************************
apaga_boneco:
	PUSH R11
	PUSH R10
	PUSH R9
	PUSH R8
	PUSH R0
	PUSH R1
	PUSH R2
	PUSH R3
	MOV R0, [R8]		; obtém a largura
	ADD R8, 2			; próximo dado na tabela
	MOV R1, [R8]		; obtém a altura
	MOV	R9, 0			; cor para apagar o próximo pixel do boneco
	MOV R2, R10			; define a coluna inicial
	MOV R3, R0			; define a largura inicial
apaga_pixels:
	ADD	R8, 2			; próximo dado da tabela
	CALL escreve_pixel	; escreve cada pixel do boneco
    ADD R10, 1			; próxima coluna
    SUB R0, 1			; menos uma coluna para tratar
    JNZ  apaga_pixels	; continua até percorrer toda a largura do boneco
	MOV R10, R2			; redefine a coluna
	MOV R0, R3			; redefine a largura
	ADD R11, 1			; próxima linha
	SUB R1, 1			; menos uma linha para tratar
	JNZ  apaga_pixels	; continua até percorrer toda a altura do boneco
	POP R3
	POP R2
	POP R1
	POP	R0
	POP	R8
	POP	R9
	POP	R10
	POP R11
	RET

; **********************************************************************
; ESCREVE_PIXEL - Escreve um pixel na linha e coluna indicadas.
; Argumentos:   R11 - linha
;               R10 - coluna
;               R9 - cor do pixel (em formato ARGB de 16 bits)
; **********************************************************************
escreve_pixel:
	MOV [DEFINE_LINHA], R11	    ; seleciona a linha
	MOV [DEFINE_COLUNA], R10	; seleciona a coluna
	MOV [DEFINE_PIXEL], R9		; altera a cor do pixel na linha e coluna já selecionadas
	RET


; ******************************************
; TECLA - Obtém o valor da tecla na linha e coluna indicadas.
; Argumentos: R11 - linha
;             R10 - coluna
; Retorna:    R9 - valor da tecla
; ******************************************
tecla:
	PUSH R10
	PUSH R11
	MOV R9, 0					; inicializa o valor a 0
tecla_linha_ciclo:
	SHR R11, 1					; avança a linha
	JZ tecla_coluna_ciclo		; se não houver mais linhas, pula para as colunas
	ADD R9, 4					; adiciona 4 ao valor
	JMP tecla_linha_ciclo		; repete até acabarem as linhas
tecla_coluna_ciclo:
	SHR R10, 1					; avança a coluna
	JZ tecla_fim				; se não houver mais colunas, termina
	ADD R9, 1					; adiciona 1 ao valor da tecla premida
	JMP tecla_coluna_ciclo		; repete até acabarem as colunas
tecla_fim:
	POP R11
	POP R10
	RET


; *****************************************************
; ESPERA_TECLA - Espera ate alguma tecla ser premida.
; Retorna: R11 - valor lido das linhas do teclado (1, 2, 4 ou 8)
;          R10 - valor lido das colunas do teclado (1, 2, 4 ou 8)
; *****************************************************
espera_tecla:
    CALL testa_linhas	; testa linhas
    CMP R10, 0
    JZ espera_tecla		; se ainda nenhuma tecla foi premida (R0 = 0), repete
    RET

; *****************************************************
; HA_TECLA - Espera ate a tecla parar de ser premida.
; Argumentos: R11 - linha a testar (1, 2, 4, 8)
; *****************************************************
ha_tecla:
    PUSH R10
ha_tecla_ciclo:
    CALL testa_linha		; testa a linha (R11) e obtém a coluna (R10)
    CMP R10, 0
    JNZ ha_tecla_ciclo		; se ainda houver uma tecla premida, repete
ha_tecla_fim:
    POP R10
    RET

; ******************************************************
; TESTA_LINHAS - Faz uma leitura às linhas e retorna a linha e a coluna da tecla premida
; Retorna: R11 - linha da tecla premida (1, 2, 4 ou 8), ou 0
;          R10 - coluna da tecla premida (1, 2, 4 ou 8), ou 0
; ******************************************************
testa_linhas:
    MOV R11, 8				; testa quarta linha
testa_linhas_ciclo:
    CALL testa_linha		; testa a linha (R11) e obtém a coluna (R10)
    CMP R10, 0				; se alguma tecla foi premida (R10 != 0)
    JNZ testa_linhas_fim	; termina
    SHR R11, 1				; linha seguinte
    CMP R11, 0				; se houver mais linhas para testar (R11 != 0)
    JNZ testa_linhas_ciclo	; testa a linha
testa_linhas_fim:
    RET

; **********************************************************************
; TESTA_LINHA - Faz uma leitura a uma linha do teclado e retorna a coluna da tecla premida
; Argumentos: R11 - linha a testar (1, 2, 4 ou 8)
; Retorna: 	  R10 - coluna da tecla premida (1, 2, 4, ou 8), ou 0	
; **********************************************************************
testa_linha:
	PUSH R0
	PUSH R1
	PUSH R2
	MOV R0, TEC_LIN	; endereço do periférico das linhas
	MOV R1, TEC_COL	; endereço do periférico das colunas
	MOV R2, MASCARA	; para isolar os 4 bits de menor peso, ao ler as colunas do teclado
	MOVB [R0], R11	; escrever no periférico de saída (linhas)
	MOVB R10, [R1]	; ler do periférico de entrada (colunas)
	AND R10, R2		; elimina bits para além dos bits 0-3
	POP	R2
	POP	R1
	POP	R0
	RET

; **********************************************************************
; ATRASO - Executa um ciclo para implementar um atraso.
; Argumentos:   R11 - valor que define o atraso
; **********************************************************************
atraso:
	PUSH R11
atraso_ciclo:
	SUB	R11, 1
	JNZ	atraso_ciclo
	POP	R11
	RET