# Implementação do Sistema de Teclado baseado em INT 9h

## Resumo das Mudanças

O código foi modificado para atender ao requerimento de usar interrupção por hardware de teclado INT 9h ao invés de INT 21h, seguindo o padrão do programa Tecbuf.

## Arquivos Modificados

### 1. keyboard.asm (NOVO)
- Implementa o sistema de interrupção de hardware INT 9h
- Contém ISR (Interrupt Service Routine) personalizado para capturar teclas
- Gerencia flags de estado para cada tecla relevante
- Funções principais:
  - `instala_isr`: Instala o handler personalizado de teclado
  - `desinstala_isr`: Restaura o handler original
  - `keyboard_isr`: Rotina de tratamento de interrupção
  - `clear_keyboard_flags`: Limpa todas as flags de teclado

### 2. main.asm
- Adicionado include do keyboard.asm
- Instalação do ISR no início do programa
- Desinstalação do ISR antes de sair do programa
- Inicialização das flags de teclado

### 3. Game.asm
- Substituição completa do loop de leitura de teclado
- Remoção de todas as chamadas `int 16h`
- Implementação de verificação de flags para:
  - Movimento (setas esquerda/direita)
  - Disparo (tecla W)
  - Pausa (tecla P)
  - Quit (tecla Q)
  - Confirmações (teclas Y/N)
  - ESC
- Limpeza adequada das flags após uso

### 4. ui.asm
- Modificação do menu principal para usar flags
- Remoção do `int 16h` do menu
- Implementação de navegação por flags para:
  - Setas cima/baixo (navegação do menu)
  - Enter (seleção)
  - ESC (sair)

## Teclas Suportadas

| Tecla | Flag | Função |
|-------|------|--------|
| ← | flag_move_esquerda | Mover jogador para esquerda |
| → | flag_move_direita | Mover jogador para direita |
| ↑ | flag_seta_cima | Navegação do menu (cima) |
| ↓ | flag_seta_baixo | Navegação do menu (baixo) |
| W | flag_atira | Disparar |
| Q | flag_fecha_jogo | Quit com confirmação |
| P | flag_pausa | Pausar/despausar jogo |
| Y | flag_confirma_sim | Confirmar (sim) |
| N | flag_confirma_nao | Confirmar (não) |
| Enter | flag_enter | Seleção do menu |
| ESC | flag_esc | Sair/cancelar |

## Funcionamento do Sistema

1. **Instalação**: O ISR é instalado no início do programa, salvando o handler original
2. **Captura**: Cada tecla pressionada/solta gera uma interrupção INT 9h
3. **Processamento**: O ISR lê o scan code da porta 60h e atualiza as flags correspondentes
4. **Uso**: O jogo verifica as flags em seus loops principais
5. **Limpeza**: As flags são limpas após serem processadas
6. **Restauração**: O handler original é restaurado ao sair do programa

## Vantagens da Implementação

- **Responsividade**: Captura imediata de eventos de teclado
- **Multitecla**: Suporte a múltiplas teclas pressionadas simultaneamente
- **Eficiência**: Não bloqueia o programa esperando entrada
- **Compatibilidade**: Segue o padrão estabelecido pelo programa Tecbuf
- **Controle**: Controle total sobre o comportamento do teclado

## Conformidade com Requisitos

✅ **Uso de INT 9h**: Implementado sistema completo baseado em interrupção de hardware
✅ **Baseado no Tecbuf**: Segue a mesma estrutura e padrão do programa de referência
✅ **Remoção do INT 21h**: Todas as chamadas `int 16h` foram removidas
✅ **Flags de Estado**: Sistema completo de flags para gerenciar estado das teclas
