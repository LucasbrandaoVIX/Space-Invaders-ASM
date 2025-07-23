# Menu de Pausa - Space Invaders 8086

## Resumo das Implementações

### 1. Strings Adicionadas (Strings.asm)
- `PausedString`: "PAUSED"
- `PressPhideString`: "Press P to resume"

### 2. Variável de Estado (Game.asm)
- `GamePausedBool`: Controla se o jogo está pausado (0=rodando, 1=pausado)

### 3. Novos Procedimentos (Game.asm)

#### ShowPauseMenu
- Exibe uma sobreposição semi-transparente
- Mostra "PAUSED" e "Press P to resume"
- Posicionado centralmente na tela

#### HidePauseMenu
- Remove a sobreposição do menu de pausa
- Redesenha todos os elementos do jogo:
  - Invasores
  - Nave do jogador
  - Tiros do jogador (se existir)
  - Tiros dos invasores

### 4. Modificações no Loop Principal

#### Detecção da Tecla P
- Scancode 19h detecta a tecla P
- Toggle entre pausado/não pausado

#### Controle de Estado
- Se pausado, ignora todas as teclas exceto P e ESC
- Se pausado, pula toda a lógica do jogo
- Mantém a verificação de teclas ativa

### 5. Inicialização
- `InitializeGame` agora define `GamePausedBool = 0` para garantir que o jogo comece sem pausa

## Como Usar
1. Durante o jogo, pressione **P** para pausar
2. Quando pausado, pressione **P** novamente para despausar
3. ESC continua funcionando para sair do jogo mesmo quando pausado

## Funcionalidades
- ✅ Pausa instantânea ao pressionar P
- ✅ Retomada sem perda de estado do jogo
- ✅ Interface visual clara indicando o estado de pausa
- ✅ Todas as outras teclas são ignoradas durante a pausa
- ✅ Redesenho automático ao despausar
- ✅ Compatível com o código existente
