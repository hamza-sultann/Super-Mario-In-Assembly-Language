INCLUDE Irvine32.inc
includelib winmm.lib
; Define the Windows function prototype
PlaySound PROTO STDCALL :PTR BYTE, :DWORD, :DWORD

; Define Flags for Sound
SND_ASYNC    EQU 1h      ; Play in background (don't freeze game)
SND_LOOP     EQU 8h      ; Loop the sound (for music)
SND_FILENAME EQU 20000h  ; The parameter is a filename
Enemy STRUCT
    x        BYTE ?       ; World X position
    y        BYTE ?       ; World Y position
    dir      BYTE 0       ; 0 = Moving Left, 1 = Moving Right
    active   BYTE 1       ; 1 = Alive, 0 = Dead
    eType    BYTE 0       ; 0 = Goomba, 1 = Turtle
    state    BYTE 0       ; 0 = Normal, 1 = Shell (Stunned)
    timer    BYTE 0       ; Countdown for Shell to wake up
Enemy ENDS
; --- HIGH SCORE DATA (Simplified) ---
HighScoreEntry STRUCT
    pName   BYTE 20 DUP(' ')  ; Name (20 bytes)
    pScore  DWORD 0           ; Score (4 bytes)
HighScoreEntry ENDS
Fireball STRUCT
    x        BYTE ?
    y        BYTE ?
    dir      BYTE ?
    active   BYTE 0
    owner    BYTE 0   ; <--- MUST BE HERE
Fireball ENDS

SMALL_RECT STRUCT
  Left   WORD ?
  Top    WORD ?
  Right  WORD ?
  Bottom WORD ?
SMALL_RECT ENDS

COORD STRUCT
  X WORD ?
  Y WORD ?
COORD ENDS

Coin STRUCT
    x BYTE ?        ; X position on screen
    y BYTE ?        ; Y position on screen
    active BYTE 1   ; 1 = Visible/Collectable, 0 = Collected/Hidden
Coin ENDS

.data

enterNameStr    BYTE "ENTER YOUR NAME: ", 0
currentPlayer   BYTE 20 DUP(0)    ; Buffer to hold player name (init with 0s)

highScoreFile   BYTE "scores.txt", 0
tempBuffer      BYTE 20 DUP(0)    ; Temp buffer for name input
scoresArray     HighScoreEntry 5 DUP(<>) ; Array to hold top 5 scores
fileHandle      DWORD ?

opt5            BYTE "5. High Scores", 0
highScoreTitle  BYTE "=== HALL OF FAME ===", 0
headerStr       BYTE "NAME                 SCORE       LEVEL", 0
tabStr          BYTE "   ", 0


hasFirePower    BYTE 0
; --- BOSS VARIABLES ---
bossDirY        BYTE 0       ; 0 = Up, 1 = Down
bossMoveTimer   BYTE 0       ; Slows down the movement
bossDir byte 1
bossActive      BYTE 0       ; 0 = Inactive, 1 = Alive
bossHealth      BYTE 10      ; Boss takes 10 hits
bossMaxHealth   BYTE 10
bossX           BYTE 20     ; Position in Level 3
bossY           BYTE 21
bossTimer       BYTE 0       ; Attack cooldown

; --- FIREBALL DATA ---
fireballs Fireball 5 DUP(<0,0,0,0,0>) ; Pool of 5 fireballs
fireSpeed     BYTE 2



isInvincible    BYTE 0        ; 0 = Normal, 1 = Invincible
invincibleTimer BYTE 0        ; Counts down time
; --- LEVEL MANAGEMENT ---
currentLevelPtr DWORD ?       ; Holds address of current level
currentLevelNum BYTE 1        ; 1 or 2

gameOverStr     BYTE "YOU DIED", 0
finalScoreStr   BYTE "Final Score: ", 0
restartMsg      BYTE "Press any key to restart...", 0

; Define 3 Goombas
enemies Enemy <25, 23, 0, 1, 0, 0, 0>, \   ; Goomba 1
              <180, 20, 1, 1, 0, 0, 0>, \   ; Goomba 2
              <75, 23, 0, 1, 1, 0, 0>      ; TURTLE (Type 1)
numEnemies DWORD ($ - enemies) / TYPE Enemy

enemySpeedCounter DWORD 0

outHandle    DWORD ?
windowRect   SMALL_RECT <0, 0, 119, 39> 
bufferSize   COORD <120, 30>

hudLabelScore   BYTE "SCORE", 0
hudLabelCoins   BYTE "COINS", 0
hudLabelWorld   BYTE "WORLD", 0
hudLabelTime    BYTE "TIME", 0
hudLabelLives   BYTE "LIVES", 0
hudStrWorld     BYTE "1-", 0  ; Will append level num dynamically

gameTime        DWORD 0
timerCounter    DWORD 0
gameLives       BYTE 5
gameCoins       BYTE 0
pauseOpt1   BYTE "1. Resume Game", 0
pauseOpt2   BYTE "2. Exit to Menu", 0

levelCompleteStr BYTE "LEVEL COMPLETE!", 0
timeBonusStr     BYTE "Time Bonus: ", 0
totalScoreStr    BYTE "Total Score: ", 0

; --- MENU & TITLE DATA ---
titleLine1  BYTE "  ____  _   _ ____  _____ ____  ", 0
titleLine2  BYTE " / ___|| | | |  _ \| ____|  _ \ ", 0
titleLine3  BYTE " \___ \| | | | |_) |  _| | |_) |", 0
titleLine4  BYTE "  ___) | |_| |  __/| |___|  _ < ", 0
titleLine5  BYTE " |____/ \___/|_|   |_____|_| \_\", 0
                                    
marioLine1  BYTE "  __  __    _    ____  ___ ___  ", 0
marioLine2  BYTE " |  \/  |  / \  |  _ \|_ _/ _ \ ", 0
marioLine3  BYTE " | |\/| | / _ \ | |_) || | | | |", 0
marioLine4  BYTE " | |  | |/ ___ \|  _ < | | |_| |", 0
marioLine5  BYTE " |_|  |_/_/   \_\_| \_\___\___/ ", 0
 marioDir byte 1
studentInfo BYTE "        Student ID: 24I-0800", 0
pressKeyMsg BYTE "     Press any key to continue...", 0

menuTitle   BYTE "======= MAIN MENU =======", 0
opt1        BYTE "1. Start Game", 0
opt2        BYTE "2. Instructions", 0
opt3        BYTE "3. Credits", 0
opt4        BYTE "4. Exit", 0
selectMsg   BYTE "Select an option: ", 0

pauseMsg    BYTE "      GAME PAUSED", 0
pausePrompt BYTE "Press any key to resume...", 0

instLine1   BYTE "--- INSTRUCTIONS ---", 0
instLine2   BYTE "Use W, A, D to move and jump.", 0
instLine3   BYTE "Avoid walls and holes.", 0
instLine4   BYTE "Collect coins (0).", 0

creditLine1 BYTE "--- CREDITS ---", 0
creditLine2 BYTE "Created by: Muhammad Hamza Sultan", 0
creditLine3 BYTE "Roll No: 24I-0800", 0

; =============================================================
; LEVEL 1 DATA
; =============================================================
level1Layout LABEL BYTE

Row0 LABEL BYTE
BYTE "================================================================================================================================================================================================================================================", 0

Row1 LABEL BYTE
BYTE "                                                                                      |_|                                                                                                                                                      |"
BYTE 240 - ($ - Row1) DUP (' ') 
BYTE 0

Row2 LABEL BYTE
BYTE "                                                                                      |_|                                                                       --------                                                                       |"
BYTE 240 - ($ - Row2) DUP (' ')
BYTE 0

Row3 LABEL BYTE
BYTE "                                                                                      |_|                                                                      (        )                                                                      |"
BYTE 240 - ($ - Row3) DUP (' ')
BYTE 0

Row4 LABEL BYTE
BYTE "                                                                                      |_|                                                                     (            )                                                                   |"
BYTE 240 - ($ - Row4) DUP (' ')
BYTE 0

Row5 LABEL BYTE
BYTE "                                                                                      |_|                                ------                              ---------------                      --------                                     |"
BYTE 240 - ($ - Row5) DUP (' ')
BYTE 0

Row6 LABEL BYTE
BYTE "                  ------                                                              |_|                              (        )                                                                (        )                                    |"
BYTE 240 - ($ - Row6) DUP (' ')
BYTE 0

Row7 LABEL BYTE
BYTE "                (        )                                                            |_|                             (            )                                                            (            )                      /1         |"
BYTE 240 - ($ - Row7) DUP (' ')
BYTE 0

Row8 LABEL BYTE
BYTE "              (            )                                                          |_|                             ---------------                                                           ---------------                    / 1         |"
BYTE 240 - ($ - Row8) DUP (' ')
BYTE 0

Row9 LABEL BYTE
BYTE "              ---------------                                                         |_| 0 0 0 % 0 0 0                                                                                                                           /  1         |"
BYTE 240 - ($ - Row9) DUP (' ')
BYTE 0

Row10 LABEL BYTE
BYTE "                                                                                      |_|_______________                                                                                                                         /   1         |"
BYTE 240 - ($ - Row10) DUP (' ')
BYTE 0

Row11 LABEL BYTE
BYTE "                                                                                      |________________|                                                                                                                        /    1         |"
BYTE 240 - ($ - Row11) DUP (' ')
BYTE 0

Row12 LABEL BYTE
BYTE "                                                                                                                                                                                                                               /  W  1         |"
BYTE 240 - ($ - Row12) DUP (' ')
BYTE 0

Row13 LABEL BYTE
BYTE "                                                                                                                                                                                                                              /_____ 1         |"
BYTE 240 - ($ - Row13) DUP (' ')
BYTE 0

Row14 LABEL BYTE
BYTE "                                                                                                                                                                                                                                     1         |"
BYTE 240 - ($ - Row14) DUP (' ')
BYTE 0

Row15 LABEL BYTE
BYTE "                                                                                                                                                                            0 0 0 0 0                                                1         |"
BYTE 240 - ($ - Row15) DUP (' ')
BYTE 0

Row16 LABEL BYTE
BYTE "                                                        0 0 0    %                  0 0 0  0  0           0 0   0 0 0                                                    _______________                                             1         |"
BYTE 240 - ($ - Row16) DUP (' ')
BYTE 0

Row17 LABEL BYTE
BYTE "                                                        0    _______________                            _______________                                                  |_|_|_|_|_|_|_|                  0                          1         |"
BYTE 240 - ($ - Row17) DUP (' ')
BYTE 0

Row18 LABEL BYTE
BYTE "                                                       0     |_|_|_|_|_|_|_|                            |_|_|_|_|_|_|_|   0                                ^^^^^^^^^                         ^^^^^^^^^                               1         |"
BYTE 240 - ($ - Row18) DUP (' ')
BYTE 0

Row19 LABEL BYTE
BYTE "                                         0 0 0 0 0 0 0                                                                     0                               !       !                         !       !         0                     1         |"
BYTE 240 - ($ - Row19) DUP (' ')
BYTE 0

Row20 LABEL BYTE
BYTE "                                      0__________________                                                                    0                             !^^^^^^^!                         !^^^^^^^!      ^^^^^^^       0          1         |"
BYTE 240 - ($ - Row20) DUP (' ')
BYTE 0

Row21 LABEL BYTE
BYTE "                                    0__|_|__|__|__|__|__|_                                                                     0                            !     !                           !     !       !^^^^^!                  1         |"
BYTE 240 - ($ - Row21) DUP (' ')
BYTE 0

Row22 LABEL BYTE
BYTE "                                   __|_|_|_|_|_|_|_|_|_|_|__                                                                     0                          !     !                           !     !         ! !                    1         |"
BYTE 240 - ($ - Row22) DUP (' ')
BYTE 0

Row23 LABEL BYTE
BYTE "                                   |_|_|_|_|_|_|_|_|_|_|_|_|                                        %                              0                        !     !                           !     !         ! !                    1         |"
BYTE 240 - ($ - Row23) DUP (' ')
BYTE 0

Row24 LABEL BYTE
BYTE "================================================================================================================================================================================================================================================", 0









; =============================================================
; LEVEL 2 DATA (Formatted with DUP for physics safety)
; =============================================================
level2Layout LABEL BYTE
L2Row0 LABEL BYTE
 byte "================================================================================================================================================================================================================================================",0
L2Row1 LABEL BYTE
byte "                                                                                                      |_|                                                                                                                                       "
BYTE 240 - ($ - L2Row1) DUP (' ')
BYTE 0
L2Row2 LABEL BYTE
byte "                                                                                                      |_|                                                         --------                                                                      "
BYTE 240 - ($ - L2Row2) DUP (' ')
BYTE 0
L2Row3 LABEL BYTE
byte "                     Level # 2 -- BEAT ME IF YOU CAN                                                  |_|                                                        (        )                                                                     "
BYTE 240 - ($ - L2Row3) DUP (' ')
BYTE 0
L2Row4 LABEL BYTE
byte "                                                                                                      |_|                                                       (            )                                                                  "
BYTE 240 - ($ - L2Row4) DUP (' ')
BYTE 0
L2Row5 LABEL BYTE
byte "                                                                                                      |_|                  ______                              ---------------                      ________                                    "
BYTE 240 - ($ - L2Row5) DUP (' ')
BYTE 0
L2Row6 LABEL BYTE
byte "                  ------                                                                              |_|                (        )                                                                (        )                                   "
BYTE 240 - ($ - L2Row6) DUP (' ')
BYTE 0
L2Row7 LABEL BYTE
byte "                (        )                                                                            |_|               (            )                                                            (            )                    /1          "
BYTE 240 - ($ - L2Row7) DUP (' ')
BYTE 0
L2Row8 LABEL BYTE
byte "              (            )                                                                          |_|               ---------------                                                           ---------------                  / 1          "
BYTE 240 - ($ - L2Row8) DUP (' ')
BYTE 0
L2Row9 LABEL BYTE
byte "              ---------------                                                             0 0 0 % 0 0 |_|                                                                                                                         /  1          "
BYTE 240 - ($ - L2Row9) DUP (' ')
BYTE 0
L2Row10 LABEL BYTE
byte "                                                                                        ______________|_|                                                                                                                        /   1          "
BYTE 240 - ($ - L2Row10) DUP (' ')
BYTE 0
L2Row11 LABEL BYTE
byte "                                                                                       |________________|                                                                                                                       /    1          "
BYTE 240 - ($ - L2Row11) DUP (' ')
BYTE 0
L2Row12 LABEL BYTE
byte "                                                                                                                                                                                                                               /  W  1          "
BYTE 240 - ($ - L2Row12) DUP (' ')
BYTE 0
L2Row13 LABEL BYTE
byte "                                                                                                                                                                                                                              /_____ 1          "
BYTE 240 - ($ - L2Row13) DUP (' ')
BYTE 0
L2Row14 LABEL BYTE
byte "                                                                                                                                                                                                                                     1          "
BYTE 240 - ($ - L2Row14) DUP (' ')
BYTE 0
L2Row15 LABEL BYTE
byte "                                                                                                                                                                            0 0 0 0 0                                                1          "
BYTE 240 - ($ - L2Row15) DUP (' ')
BYTE 0
L2Row16 LABEL BYTE
byte "                                                         0 0 0                      0 0 0  0  0           0 0 0 0 0 0                                                    _______________                                             1          "
BYTE 240 - ($ - L2Row16) DUP (' ')
BYTE 0
L2Row17 LABEL BYTE
byte "                                                        0    _____________________________________      ^^^^^^^^                                                         |_|_|_|_|_|_|_|                  0                          1          "
BYTE 240 - ($ - L2Row17) DUP (' ')
BYTE 0
L2Row18 LABEL BYTE
byte "                                                       0     |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|      !      !                                           ^^^^^^^^^                         ^^^^^^^^^                               1          "
BYTE 240 - ($ - L2Row18) DUP (' ')
BYTE 0
L2Row19 LABEL BYTE
byte "                                         0 0 0 0 0 0 0                                                  !      !            0                              !       !                         !       !         0                     1          "
BYTE 240 - ($ - L2Row19) DUP (' ')
BYTE 0
L2Row20 LABEL BYTE
byte "                                      0 _________________                                               !      !              0                            !       !                         !       !      ^^^^^^^       0          1          "
BYTE 240 - ($ - L2Row20) DUP (' ')
BYTE 0
L2Row21 LABEL BYTE
byte "                                    0__|_|__|__|__|__|__|                                                !    !                 0                           !     !                           !     !       !     !                  1          "
BYTE 240 - ($ - L2Row21) DUP (' ')
BYTE 0
L2Row22 LABEL BYTE
byte "                                   __|_|_|                                                               !    !                    0                        !     !                           !     !         ! !                    1          "
BYTE 240 - ($ - L2Row22) DUP (' ')
BYTE 0
L2Row23 LABEL BYTE
byte "                                   |_|_|_| 0 0 % 0 0 0 0                                                 !    !                      0                      !     !                           !     !         ! !                    1          "
BYTE 240 - ($ - L2Row23) DUP (' ')
BYTE 0
L2Row24 LABEL BYTE
BYTE "================================================================================================================================================================================================================================================"

level1RowSize byte 241  ; 240 chars + null terminator
worldX BYTE 0
worldY BYTE 0
cameraX BYTE 0

; =============================================================
; LEVEL 3: BOWSER'S CASTLE (NO MOVING PLATFORMS)
; =============================================================
leveL3Layout LABEL BYTE
L3Row0 LABEL BYTE
 byte "================================================================================================================================================================================================================================================",0
L3Row1 LABEL BYTE
byte "                                                                                                      |_|                                                                                                                                       "
BYTE 240 - ($ - L3Row1) DUP (' ')
BYTE 0
L3Row2 LABEL BYTE
byte "                                                                                                      |_|                                                         --------                                                                      "
BYTE 240 - ($ - L3Row2) DUP (' ')
BYTE 0
L3Row3 LABEL BYTE
byte "                     Level # 2 -- BEAT ME IF YOU CAN                                                  |_|                                                        (        )                                                                     "
BYTE 240 - ($ - L3Row3) DUP (' ')
BYTE 0
L3Row4 LABEL BYTE
byte "                                                                                                      |_|                                                       (            )                                                                  "
BYTE 240 - ($ - L3Row4) DUP (' ')
BYTE 0
L3Row5 LABEL BYTE
byte "                                                                                                      |_|                  ______                              ---------------                      ________                                    "
BYTE 240 - ($ - L3Row5) DUP (' ')
BYTE 0
L3Row6 LABEL BYTE
byte "                  ------                                                                              |_|                (        )                                                                (        )                                   "
BYTE 240 - ($ - L3Row6) DUP (' ')
BYTE 0
L3Row7 LABEL BYTE
byte "                (        )                                                                            |_|               (            )                                                            (            )                    /1          "
BYTE 240 - ($ - L3Row7) DUP (' ')
BYTE 0
L3Row8 LABEL BYTE
byte "              (            )                                                                          |_|               ---------------                                                           ---------------                  / 1          "
BYTE 240 - ($ - L3Row8) DUP (' ')
BYTE 0
L3Row9 LABEL BYTE
byte "              ---------------                                                             0 0 0 % 0 0 |_|                                                                                                                         /  1          "
BYTE 240 - ($ - L3Row9) DUP (' ')
BYTE 0
L3Row10 LABEL BYTE
byte "                                                                                        ______________|_|                                                                                                                        /   1          "
BYTE 240 - ($ - L3Row10) DUP (' ')
BYTE 0
L3Row11 LABEL BYTE
byte "                                                                                       |________________|                                                                                                                       /    1          "
BYTE 240 - ($ - L3Row11) DUP (' ')
BYTE 0
L3Row12 LABEL BYTE
byte "                                                                                                                                                                                                                               /  W  1          "
BYTE 240 - ($ - L3Row12) DUP (' ')
BYTE 0
L3Row13 LABEL BYTE
byte "                                                                                                                                                                                                                              /_____ 1          "
BYTE 240 - ($ - L3Row13) DUP (' ')
BYTE 0
L3Row14 LABEL BYTE
byte "                                                                                                                                                                                                                                     1          "
BYTE 240 - ($ - L3Row14) DUP (' ')
BYTE 0
L3Row15 LABEL BYTE
byte "                                                                                                                                                                            0 0 0 0 0                                                1          "
BYTE 240 - ($ - L3Row15) DUP (' ')
BYTE 0
L3Row16 LABEL BYTE
byte "                                                         0 0 0                      0 0 0  0  0           0 0 0 0 0 0                                                    _______________                                             1          "
BYTE 240 - ($ - L3Row16) DUP (' ')
BYTE 0
L3Row17 LABEL BYTE
byte "                                                        0    _____________________________________      ^^^^^^^^                                                         |_|_|_|_|_|_|_|                  0                          1          "
BYTE 240 - ($ - L3Row17) DUP (' ')
BYTE 0
L3Row18 LABEL BYTE
byte "                                                       0     |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|      !      !                                           ^^^^^^^^^                         ^^^^^^^^^                               1          "
BYTE 240 - ($ - L3Row18) DUP (' ')
BYTE 0
L3Row19 LABEL BYTE
byte "                                         0 0 0 0 0 0 0                                                  !      !            0                              !       !                         !       !         0                     1          "
BYTE 240 - ($ - L3Row19) DUP (' ')
BYTE 0
L3Row20 LABEL BYTE
byte "                                      0 _________________                                               !      !              0                            !       !                         !       !      ^^^^^^^       0          1          "
BYTE 240 - ($ - L3Row20) DUP (' ')
BYTE 0
L3Row21 LABEL BYTE
byte "                                    0__|_|__|__|__|__|__|                                                !    !                 0                           !     !                           !     !       !     !                  1          "
BYTE 240 - ($ - L3Row21) DUP (' ')
BYTE 0
L3Row22 LABEL BYTE
byte "                                   __|_|_|                                                               !    !                    0                        !     !                           !     !         ! !                    1          "
BYTE 240 - ($ - L3Row22) DUP (' ')
BYTE 0
L3Row23 LABEL BYTE
byte "                                   |_|_|_| 0 0 % 0 0 0 &                                                 !    !                      0                      !     !                           !     !         ! !                    1          "
BYTE 240 - ($ - L3Row23) DUP (' ')
BYTE 0
L3Row24 LABEL BYTE
BYTE "================================================================================================================================================================================================================================================"

; Variables
canMoveLeft BYTE 1
canMoveRight BYTE 1
coins Coin <10, 40, 1>, \
           <15, 15, 1>, \
           <16, 15, 1>, \
           <17, 15, 1>, \
           <40, 25, 1>, \
           <5, 10, 1>, \
           <20, 5, 1>, \
           <25, 12, 1>, \
           <30, 8, 1>, \
           <35, 18, 1>, \
           <50, 20, 1>, \
           <45, 10, 1>, \
           <12, 22, 1>, \
           <28, 30, 1>, \
           <38, 6, 1>

numCoins DWORD ($ - coins) / TYPE Coin
groundY BYTE 25
strScore BYTE "Your score is: ",0
score dword  0
lastScore Dword 0FFFFFFFFh 
moveSpeed BYTE 6 
xprev byte 0
yprev byte 0
xdummy byte 0
ydummy byte 0
xpostemp byte 15
ypostemp byte 20
xPos BYTE 15
yPos BYTE 18
gravity BYTE 2
velocityY BYTE 0
isJumping BYTE 0

xCoinPos BYTE ?
yCoinPos BYTE ?
cameraMoved BYTE 0    
MAX_SCROLL EQU 110    
inputChar BYTE ?
movedLeft BYTE 0
movedRight BYTE 0
cursorInfo CONSOLE_CURSOR_INFO <>
bgMusicFile   BYTE "music.wav", 0    ; Rename to your file
menuMusicFile   BYTE "menu.wav", 0   ; Make sure this file exists!
fireSfxFile   BYTE "fire.wav", 0     ; Rename to your file
jumpSfxFile   BYTE "jump.wav", 0     ; Rename to your file
invincibleSfx   BYTE "invincibility.wav", 0  ; Make sure this file is in your folder
.code
main PROC
    ; --- 1. RESIZE CONSOLE ---
    call SetupConsole
    call HideCursor
    
    ; 2. Show Title Screen
    call ShowTitleScreen
    
    ; 3. Show Main Menu
MenuLoopLabel:
    call ShowMainMenu
    cmp al, '1'
    je InitGame
    cmp al, '4'
    je ExitTheGame
    jmp MenuLoopLabel

InitGame:
    call Clrscr
    
    ; 1. Ask Name
    mov dh, 12
    mov dl, 45
    call Gotoxy
    mov eax, white + (black * 16)
    call SetTextColor
    mov edx, OFFSET enterNameStr
    call WriteString
    
    ; 2. Save Name
    mov edx, OFFSET currentPlayer
    mov ecx, 19
    call ReadString
    
    call PlayBackgroundMusic    ; <--- ADD THIS LINE

    ; 3. Setup Level
    mov currentLevelNum, 3
    mov currentLevelPtr, OFFSET level3Layout
    call SetupLevel3
    
    ; 4. Reset Variables
    mov xPos, 15
    mov yPos, 18
    mov cameraX, 0
    mov score, 0
    mov gameCoins, 0
    mov gameLives, 3
    mov gameTime, 0
    
    jmp StartTheGame
StartTheGame:
    call Clrscr
    ; Draw Initial State
    call DrawLevel
    call DrawPlayer
    call Randomize

    ; Initialize Position Trackers
    mov al, xPos
    mov xPrev, al
    mov al, yPos
    mov yPrev, al

gameLoop:
; ---------------------------
    ; 1. TIMER & HUD LOGIC
    ; ---------------------------
    inc timerCounter
    cmp timerCounter, 20    
    jne SkipTimer
    
    mov timerCounter, 0
    inc gameTime            
    call DrawHUD            
    
    ; --- INVINCIBILITY TIMER (1 Second Decrement) ---
    cmp isInvincible, 1
    jne SkipTimer
    dec invincibleTimer
    jnz SkipTimer
    mov isInvincible, 0
    ; Timer reached 0 -> Disable Invincibility
    mov isInvincible, 0
    call PlayBackgroundMusic   ; <--- ADD THIS
SkipTimer:
    ; Optimization: Only redraw Score/Coins if changed
    mov eax, score
    cmp eax, lastScore
    je ReadInput            
    
    mov lastScore, eax
    call DrawHUD     

    ; ---------------------------
    ; 3. INPUT LOGIC
    ; ---------------------------
ReadInput:
    call ReadKey
    jz CheckMovementFlags   ; If no key, go straight to Physics
    
    mov inputChar, al

    ; --- PAUSE CHECK ---
    cmp inputChar, "p"
    je TriggerPause
    cmp inputChar, "P"
    je TriggerPause

    ; --- SHOOTING CHECK ('f') ---
    cmp inputChar, "f"
    je TryPlayerShoot
    cmp inputChar, "F"
    je TryPlayerShoot

    cmp inputChar, "x"
    je MenuLoopLabel    

    cmp inputChar, "w"
    je TryJump
    jmp CheckAD
TryPlayerShoot:
    ; 1. CHECK POWERUP
    cmp hasFirePower, 1
    jne CheckMovementFlags  ; If no power, ignore key

    ; 2. Calculate World X -> Put in DL
    movzx edx, xPos         ; Load Screen X into EDX
    add dl, cameraX         ; Add Camera to get World X in DL
    
    ; 3. Setup Y -> Put in DH
    mov dh, yPos            ; Load Y into DH
    
    ; 4. Setup Direction & Owner
    mov al, marioDir      ; AL = Direction (1=Right, 0=Left)
    mov ah, 0               ; AH = Owner (0 = PLAYER)
    
    call SpawnFireball
    jmp CheckMovementFlags
TriggerPause:
    call PauseGame      
    cmp al, 2
    je MenuLoopLabel    
    
    ; On Resume, redraw everything
    call DrawLevel
    call DrawHUD
    call DrawEnemies
    call DrawPlayer
    jmp gameLoop

TryJump:
    cmp isJumping, 1
    je CheckAD
    mov velocityY, -5
    mov isJumping, 1
    jmp CheckMovementFlags

CheckAD:
    cmp inputChar, "a"
    je SetLeft
    cmp inputChar, "d"
    je SetRight
    jmp CheckMovementFlags

SetLeft:
    mov movedLeft, 1
    mov marioDir, 0
    jmp CheckMovementFlags
SetRight:
    mov movedRight, 1
    mov marioDir, 1
    ; ---------------------------
    ; 4. PHYSICS LOGIC
    ; ---------------------------
CheckMovementFlags:
    mov al, xPos
    mov xpostemp, al
    mov al, yPos
    mov ypostemp, al

    ; --- GRAVITY ---
    mov al, xPos
    mov xPrev, al
    mov al, yPos
    mov yPrev, al         
    mov yPrev, al         

    movsx ax, velocityY
    add yPrev, al
    movsx ax, gravity
    add velocityY, al

    call CheckFloorCollision
    
    mov al, yPrev
    mov yPos, al
    
    call CheckItemCollision
    
    ; --- CHECK WIN CONDITION ---
    call CheckFlagCollision
    cmp al, 1                ; Did we hit the flag?
    je HandleWin
    jmp ContinuePhysics

HandleWin:
    cmp currentLevelNum, 1
    je SwitchToLevel2
    cmp currentLevelNum, 2  ; <--- CHECK LEVEL 2
    je StartLevel3          ; <--- GO TO LEVEL 3
    jmp VictorySequence      ; Level 2 complete = End Game

SwitchToLevel2:
    mov currentLevelNum, 2
    mov currentLevelPtr, OFFSET level2Layout
    
    ; Reset Positions for Level 2
    mov xPos, 15
    mov yPos, 18
    mov cameraX, 0
    mov velocityY, 0
    mov isJumping, 0
    
    call Clrscr
    call DrawLevel
    call DrawHUD
    jmp gameLoop
StartLevel3:
    call Clrscr
    call SetupLevel3
    call DrawLevel ; Draw it once to init
    call DrawHUD
    jmp gameLoop

VictorySequence:
    call ShowLevelComplete ; Shows score
    jmp MenuLoopLabel      ; Back to Main Menu

ContinuePhysics:
    call UpdateEnemies      ; Move Goombas
    ; --- ADD BOSS LOGIC ---
    cmp currentLevelNum, 3
    jne SkipBossUpdate
    call UpdateBoss
    call UpdateFireballs
SkipBossUpdate:
    ; ---------------------------
    ; 5. DRAW LOGIC
    ; ---------------------------
DoRedraw:
    ; Calculate if Mario needs to be erased (Swap Logic)
    mov al, yPos
    cmp al, ypostemp
    jne UseSwapLogic    
    cmp isJumping, 1
    je UseSwapLogic
    jmp EraseNormal

UseSwapLogic:
    push ax
    mov al, xPos
    mov xdummy, al
    mov al, yPos
    mov ydummy, al
    mov al, xpostemp
    mov xPos, al
    mov al, ypostemp
    mov yPos, al
    pop ax
    call UpdatePlayer       ; Erase old spot
    push ax
    mov al, xdummy
    mov xPos, al
    mov al, ydummy
    mov yPos, al
    pop ax
    jmp UpdateHorizontal

EraseNormal:
    call UpdatePlayer       ; Erase current spot

UpdateHorizontal:
    ; --- LEFT MOVEMENT ---
    cmp movedLeft, 1
    jne CheckRightMove
    
    movzx ecx, moveSpeed    
MoveLeftLoop:
    push ecx                
    call CheckWallLeft
    cmp canMoveLeft, 0
    je StopLeft             

    cmp xPos, 60
    jg NormalLeft
    cmp cameraX, 0
    jle NormalLeft
    
    dec cameraX             
    mov cameraMoved, 1      
    call CheckItemCollision 
    jmp NextLeftStep
NormalLeft:
    dec xPos                
    call CheckItemCollision 
NextLeftStep:
    pop ecx                 
    loop MoveLeftLoop       
    jmp FinishLeft
StopLeft:
    pop ecx                 
FinishLeft:
    mov movedLeft, 0
    jmp DrawNewMario

    ; --- RIGHT MOVEMENT ---
CheckRightMove:
    cmp movedRight, 1
    jne DrawNewMario
    
    movzx ecx, moveSpeed    
MoveRightLoop:
    push ecx                
    call CheckWallRight
    cmp canMoveRight, 0
    je StopRight            

    cmp xPos, 60
    jl NormalRight
    cmp cameraX, 120        
    jge NormalRight
    
    inc cameraX             
    mov cameraMoved, 1      
    call CheckItemCollision 
    jmp NextRightStep
NormalRight:
    inc xPos
    call CheckItemCollision 
NextRightStep:
    pop ecx                 
    loop MoveRightLoop      
    jmp FinishRight
StopRight:
    pop ecx                 
FinishRight:
    mov movedRight, 0

DrawNewMario:
    ; ==========================================
    ;   MASTER DRAWING SECTION
    ; ==========================================
    
    cmp cameraMoved, 1
    jne DrawObjects
    
    ; If Camera Scrolled:
    call DrawLevel       ; Wipe Screen
    call DrawHUD         ; Draw HUD
    mov cameraMoved, 0

DrawObjects:
   call DrawEnemies    
    call DrawPlayer     

    ; --- ADD BOSS DRAWING ---
    cmp currentLevelNum, 3
    jne SkipBossDraw
    call DrawBoss
    call DrawFireballs
SkipBossDraw:
    ; Sync Physics
    mov al, yPos
    mov yPrev, al

    ; Frame Delay
    mov eax, 50
    call Delay
    jmp gameLoop

ExitTheGame:
    exit
main ENDP

; -------------------------------------------------------------------
; PROCEDURES (UPDATED TO USE currentLevelPtr)
; -------------------------------------------------------------------

CheckFloorCollision PROC
    movzx bx, yPos                
    movzx dx, yPrev               
    
checkLoop:
    inc bx                        
    cmp bl, yPrev
    jg noFallCollision            

    ; Calculate Address
    mov ax, 241                   
    mul bx                        ; y * 241
    movsx cx, xPrev               
    add ax, cx                    ; + x
    movzx cx, cameraX             
    add ax, cx                    ; + camera

    movzx eax, ax
    mov esi, currentLevelPtr  ; <--- UPDATED
    add esi, eax
    ; --- LAVA CHECK (NEW) ---
    cmp byte ptr [esi], '~'
    je LavaDeath
    ; --- ONLY LAND ON FLAT SURFACES ---
    cmp byte ptr [esi], '_'      ; Ground Top
    je landed
    cmp byte ptr [esi], '='      ; Block
    je landed
    cmp byte ptr [esi], '^'      ; Pipe Top
    je landed
    
    jmp checkLoop
LavaDeath:
    call KillMarioProc ; Die immediately
    ret

noFallCollision:
    ret

landed:
    mov isJumping, 0
    mov velocityY, 0
    mov al, bl
    sub al, 1
    mov yPrev, al                ; Snap to top
    mov yPos, al                 ; Update current Pos immediately
    ret
CheckFloorCollision ENDP

DrawPlayer PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    ; --- 1. Move Cursor ---
    mov dl, xPos
    mov dh, yPos
    call Gotoxy

    ; --- 2. CHECK INVINCIBILITY (Far Jump Fix) ---
    cmp isInvincible, 1
    jne CheckFirePower      ; If NOT invincible, skip to next check
    jmp SetStarMode         ; If Invincible, Long Jump to Star Mode

CheckFirePower:
    cmp hasFirePower, 1
    jne CheckMapColor       ; If NO fire power, skip to map check
    jmp SetBrownMode        ; If Fire Power, Long Jump to Brown Mode

    ; --- 3. Normal Color Logic ---
CheckMapColor:
    movzx eax, yPos
    mov ebx, 241
    mul ebx                 
    movzx ebx, xPos
    add eax, ebx            
    movzx ebx, cameraX
    add eax, ebx            
    
    mov esi, currentLevelPtr
    add esi, eax            
    mov al, [esi]           

    cmp al, '='
    je DrawOnGround
    cmp al, '|'
    je DrawOnGround
    cmp al, '_'
    je DrawOnGround
    
    jmp DrawOnSky

; --- COLOR HANDLERS ---
SetStarMode:
    ; Flash Colors based on Timer
    mov eax, gameTime
    and eax, 12         ; Mask bits 2 and 3
    
    cmp eax, 0
    je StarColor1
    cmp eax, 4
    je StarColor2
    cmp eax, 8
    je StarColor3
    
    ; Color 4
    mov eax, 11 + (1 * 16) ; Cyan on Blue
    call SetTextColor
    jmp PrintMario

StarColor1:
    mov eax, 15 + (4 * 16) ; White on Red
    call SetTextColor
    jmp PrintMario
StarColor2:
    mov eax, 12 + (15 * 16); Red on White
    call SetTextColor
    jmp PrintMario
StarColor3:
    mov eax, 14 + (0 * 16) ; Yellow on Black
    call SetTextColor
    jmp PrintMario

SetBrownMode:
    mov eax, 15 + (6 * 16)  ; Brown Background
    call SetTextColor
    jmp PrintMario

DrawOnGround:
    mov eax, 15 + (4 * 16)  
    call SetTextColor
    jmp PrintMario

DrawOnSky:
    mov eax, 12 + (9 * 16)  
    call SetTextColor
    jmp PrintMario

PrintMario:
    mov al, 'X'             
    call WriteChar

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
DrawPlayer ENDP

UpdatePlayer PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    ; --- 1. Calculate Address ---
    movzx eax, yPos         
    mov ebx, 241            
    mul ebx                 
    
    movzx ebx, xPos         
    add eax, ebx            
    
    movzx ebx, cameraX      
    add eax, ebx            

    mov esi, currentLevelPtr  ; <--- UPDATED
    add esi, eax            
    
    mov bl, [esi]           

    ; --- 2. Move Cursor ---
    mov dl, xPos
    mov dh, yPos
    call Gotoxy

    ; --- 3. RESTORE BACKGROUND COLOR ---
    
    ; Ground (Red)
    cmp bl, '='
    je SetGround
    cmp bl, '|'
    je SetGround
    cmp bl, '_'
    je SetGround
    
    ; Green Pipes
    cmp bl, '!'          
    je SetPipeWall
    cmp bl, '^'          
    je SetPipeTop

    ; Items/Clouds
    cmp bl, '0'
    je SetYellow
    cmp bl, '('
    je SetCloudChar
    cmp bl, ')'
    je SetCloudChar
    cmp bl, '-'
    je SetCloudChar

    ; Default Sky (Dark Blue)
    mov eax, 1 + (1 * 16)   
    jmp ApplyColor

SetGround:
    mov eax, 0 + (4 * 16)   ; Red Background (64)
    jmp ApplyColor

SetPipeWall:
    mov eax, 0 + (2 * 16)   ; Green Background
    call SetTextColor
    mov al, '|'             ; Force correct character
    call WriteChar
    jmp EndUpdate

SetPipeTop:
    mov eax, 0 + (2 * 16)   ; Green Background
    call SetTextColor
    mov al, '_'             ; Force correct character
    call WriteChar
    jmp EndUpdate

SetCloudChar:
    mov eax, 15 + (1 * 16)
    jmp ApplyColor

SetYellow:
    mov eax, 14 + (1 * 16)
    jmp ApplyColor

ApplyColor:
    call SetTextColor       
    
    mov al, bl              ; Move the saved character back to AL
    call WriteChar          

EndUpdate:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
UpdatePlayer ENDP










DrawLevel PROC
    push esi
    push edi
    push ecx
    push eax
    push edx
    push ebx

    mov ecx, 25              ; Loop 25 rows
    mov edi, currentLevelPtr 

DrawRowLoop:
    ; --- 1. Calculate Base Row Address (World X=0) ---
    mov eax, 241
    mov ebx, 25
    sub ebx, ecx             
    mul ebx                  
    mov esi, edi
    add esi, eax             ; ESI = Start of the row (Index 0)

    ; ===============================================================
    ;   FIX: PRE-SCAN STATE FROM X=0 TO CAMERA_X
    ;   This ensures EDX is correct if we start drawing inside a pipe
    ; ===============================================================
    xor edx, edx             ; Default State: 0 (Outside)
    movzx ebx, cameraX       ; We need to scan 'cameraX' amount of characters
    
    cmp ebx, 0
    je StartDrawing          ; If camera is at 0, skip scan

PreScanLoop:
    mov al, [esi]            ; Read character at current World X
    
    ; --- Check Triggers (Same logic as drawing) ---
    cmp al, '!'
    je TogglePipePre
    cmp al, '('
    je EnterCloudPre
    cmp al, ')'
    je ExitCloudPre
    jmp AdvancePre

TogglePipePre:
    cmp edx, 2      ; Are we currently inside?
    je LeavePipePre
    mov edx, 2      ; No, so enter pipe
    jmp AdvancePre
LeavePipePre:
    mov edx, 0      ; Yes, so leave pipe
    jmp AdvancePre

EnterCloudPre:
    mov edx, 1
    jmp AdvancePre
ExitCloudPre:
    mov edx, 0
    jmp AdvancePre

AdvancePre:
    inc esi         ; Move to next character
    dec ebx         ; Decrement counter
    jnz PreScanLoop ; Continue until we reach CameraX

    ; ===============================================================
    ;   END FIX - Now ESI is at the Screen Start, and EDX is correct
    ; ===============================================================

StartDrawing:
    ; --- 3. Move Cursor ---
    mov dl, 0
    mov eax, 25
    sub eax, ecx
    mov dh, al               ; DH = Current Row
    call Gotoxy

    ; --- 4. DRAW 120 CHARACTERS ---
    mov ebx, 120             

PrintCharLoop:
        mov al, [esi]        ; Load map char

        ; ==============================
        ;   MARIO CHECK (Inline)
        ; ==============================
        cmp dh, yPos
        jne CheckStateTriggers
        
        push eax
        mov eax, 120
        sub eax, ebx
        cmp al, xPos
        pop eax
        je DrawMarioInline    

CheckStateTriggers:
        ; ==============================
        ;       STATE TRIGGERS
        ; ==============================
        cmp al, '!'
        je TogglePipeState
        cmp al, '('
        je EnterCloud
        cmp al, ')'
        je ExitCloud
         cmp al, '%'
        je DrawMushroom
        cmp al,'&'
        je drawFireFlower

        ; ==============================
        ;       FILL LOGIC
        ; ==============================
        cmp edx, 2           ; Inside Pipe?
        je PipeFillLogic
        cmp edx, 1           ; Inside Cloud?
        je CloudFillLogic
        jmp NormalColorLogic 

    ; --- MARIO DRAWING ---
DrawMarioInline:
        ; Simple Logic: Ground = White/Red, Sky = Red/Blue
        cmp al, '='
        je DrawMarioGround
        cmp al, '|'
        je DrawMarioGround
        cmp al, '_'
        je DrawMarioGround
        cmp al, '!'
        je DrawMarioGround
        cmp al, '^'
        je DrawMarioGround
       
        cmp al, '1'          ; Stand on Pole
        je DrawMarioGround
        
        ; Sky/Flag
        mov eax, 12 + (1 * 16) ; Red X on Blue
        call SetTextColor
        mov al, 'X'
        call WriteChar
        jmp AdvanceLoop
DrawMushroom:
        mov eax, 12 + (15 * 16) ; Red Text on White BG
        call SetTextColor
        call WriteChar
        jmp AdvanceLoop
DrawFireFlower:
        mov eax, 10 + (red * 16) ; Light Red Text (12) on White BG (15)
        call SetTextColor
        call WriteChar
        jmp AdvanceLoop
DrawMarioGround:
        mov eax, 15 + (4 * 16) ; White X on Red
        call SetTextColor
        mov al, 'X'
        call WriteChar
        jmp AdvanceLoop

    ; --- STATE HANDLERS ---
    TogglePipeState:
        cmp edx, 2
        je LeavePipe
        mov edx, 2           
        jmp SetPipeWall
    LeavePipe:
        mov edx, 0           
        jmp SetPipeWall

    EnterCloud:
        mov edx, 1           
        jmp SetCloudChar     
    ExitCloud:
        mov edx, 0           
        jmp SetCloudChar     
        
    ; --- FILL LOGIC ---
    PipeFillLogic:
        cmp al, ' '          
        je SetSolidGreen     
        cmp al, '0'
        je SetCoinInPipe     
        jmp NormalColorLogic 

    CloudFillLogic:
        cmp al, ' '          
        je SetSolidWhite     
        jmp NormalColorLogic 

    ; ==============================
    ;       NORMAL LOGIC
    ; ==============================
    NormalColorLogic:
        ; Ground
        cmp al, '='
        je SetGround
        cmp al, '|'
        je SetGround
        cmp al, '_'
        je SetGround
        
        ; Green Pipes
        cmp al, '^'
        je SetPipeTop
        
        ; NEW: Flag Pole & Flag
        cmp al, '1'          ; Magic Char for Pole
        je SetFlagPole
        cmp al, '/'
        je SetFlagYellow
        cmp al, 'W'
        je SetFlagYellow
        cmp al, '\'          ; Backslash just in case
        je SetFlagYellow

        ; Items
        cmp al, '0'
        je SetYellow
        
        ; Cloud
        cmp al, '-'
        je SetCloudChar      

        ; Sky
        mov eax, 1 + (1 * 16) 
        jmp ApplyColor

    ; ==============================
    ;       COLOR SETTERS
    ; ==============================
    SetGround:
        mov eax, 0 + (red * 16) 
        jmp ApplyColor
    SetPipeWall:
        mov eax, 0 + (2 * 16)
        call SetTextColor
        mov al, '|'           
        call WriteChar
        jmp AdvanceLoop
    SetPipeTop:
        mov eax, 0 + (2 * 16)
        call SetTextColor
        mov al, '_'           
        call WriteChar
        jmp AdvanceLoop
    
    ; --- NEW FLAG COLORS ---
    SetFlagPole:
        mov eax, 0 + (2 * 16)   ; Black Text on Green BG (Like Pipe)
        call SetTextColor
        mov al, '|'             ; SWAP 1 -> |
        call WriteChar
        jmp AdvanceLoop

    SetFlagYellow:
        mov eax, 14 + (1 * 16)  ; Yellow Text on Blue BG
        jmp ApplyColor
    ; -----------------------

    SetSolidGreen:
        mov eax, 2 + (2 * 16)
        jmp ApplyColor
    SetCoinInPipe:
        mov eax, 14 + (2 * 16)
        jmp ApplyColor
    SetCloudChar:
        mov eax, 15 + (1 * 16)
        jmp ApplyColor
    SetSolidWhite:
        mov eax, 15 + (15 * 16) 
        jmp ApplyColor
    SetYellow:
        mov eax, 14 + (1 * 16)  
        jmp ApplyColor

    ApplyColor:
        call SetTextColor
        mov al, [esi]        
        call WriteChar       
        
    AdvanceLoop:
        inc esi
        dec ebx              
        jnz PrintCharLoop    

    dec ecx                  
    jnz DrawRowLoop          

    pop ebx
    pop edx
    pop eax
    pop ecx
    pop edi
    pop esi
    ret
DrawLevel ENDP













HideCursor PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outHandle, eax
    INVOKE GetConsoleCursorInfo, outHandle, ADDR cursorInfo
    mov cursorInfo.bVisible, 0       
    INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo
    ret
HideCursor ENDP















CheckItemCollision PROC
    push eax
    push ebx
    push esi
    push edx

    ; --- 1. Calculate Address ---
    movzx eax, yPos         
    mov ebx, 241            
    mul ebx                 
    movzx ebx, xPos         
    add eax, ebx            
    movzx ebx, cameraX      
    add eax, ebx            
    
    mov esi, currentLevelPtr 
    add esi, eax            

    ; --- 2. Check Item ---
    mov al, [esi]
    cmp al, '0'
    je FoundCoin
    cmp al, '%'          ; Check for Mushroom
    je FoundMushroom
    cmp al, '&'          
    je FoundFireFlower   
    
    ; Check Head (Jump)
    mov al, [esi - 241]
    cmp al, '0'
    je FoundCoinHead
    cmp al, '%'
    je FoundMushroomHead

    jmp EndCheck

FoundCoinHead:
    sub esi, 241
    jmp FoundCoin
FoundMushroomHead:
    sub esi, 241
    jmp FoundMushroom
FoundFireFlower:
    add score, 1000         ; Points
    mov hasFirePower, 1     ; ENABLE SHOOTING
    mov byte ptr [esi], ' ' ; Erase Item
    call EraseItemVisual
    jmp EndCheck
FoundCoin:
    inc score           
    inc gameCoins       
    mov byte ptr [esi], ' ' 
    call EraseItemVisual
    jmp EndCheck

FoundMushroom:
    add score, 1000           ; +50 Points (Fits in BYTE)
    mov isInvincible, 1     ; Enable God Mode
    mov invincibleTimer, 5  ; 5 Seconds
    mov byte ptr [esi], ' ' ; Remove Item
    call EraseItemVisual
    call PlayInvincibleSound
    jmp EndCheck

EraseItemVisual:
    ; Helper to erase the item from screen immediately
    push eax
    push edx
    mov dl, xPos
    mov dh, yPos
    call Gotoxy
    
    ; Default to Blue Sky to keep it simple without GetBackgroundColor
    mov eax, 1 + (1 * 16)   
    call SetTextColor
    mov al, ' '
    call WriteChar
    
    pop edx
    pop eax


    mov eax, 0FFFFFFFFh
    mov lastScore, eax      ; Force HUD Update
    ret

EndCheck:
    pop edx
    pop esi
    pop ebx
    pop eax
    ret
CheckItemCollision ENDP















CheckWallLeft PROC
    push ax
    push bx
    
    ; 1. Calculate Target X (Current X - 1)
    mov al, xPos
    dec al              
    
    ; 2. Add Camera Offset
    mov ah, cameraX
    add al, ah
    mov worldX, al
    
    ; 3. Setup Y
    mov bl, yPos
    mov worldY, bl

    call GetTile
    
    ; 5. COLLISION CHECKS
    cmp al, '|'         ; Red Ground Wall
    je blockLeft
    
    cmp al, '!'         ; NEW: Green Pipe Wall
    je blockLeft        ; Treat '!' as solid
    
    mov canMoveLeft, 1
    jmp doneLeft

blockLeft:
    mov canMoveLeft, 0

doneLeft:
    pop bx
    pop ax
    ret
CheckWallLeft ENDP










CheckWallRight PROC
    push ax
    push bx
    
    ; 1. Calculate Target X (Current X + 1)
    mov al, xPos
    inc al              
    
    ; 2. Add Camera Offset
    mov ah, cameraX
    add al, ah
    mov worldX, al      
    
    ; 3. Setup Y
    mov bl, yPos
    mov worldY, bl

    ; 4. Get Tile
    call GetTile
    
    ; 5. COLLISION CHECKS
    cmp al, '|'         ; Red Ground Wall
    je blockRight
    
    cmp al, '!'         ; NEW: Green Pipe Wall
    je blockRight       ; Treat '!' as solid
    
    mov canMoveRight, 1
    jmp doneRight

blockRight:
    mov canMoveRight, 0

doneRight:
    pop bx
    pop ax
    ret
CheckWallRight ENDP












GetTile PROC
    push esi
    push ebx
    push edx

    ; --- 1. Calculate Row Offset ---
    ; Row Offset = worldY * 241
    mov bl, worldY
    movzx esi, bl            ; Move Y to ESI
    mov eax, 241             ; Row Width
    mul esi                  ; EAX = Y * 241
    
    ; --- 2. Add Base Address ---
    mov esi, eax
    add esi, currentLevelPtr ; <--- UPDATED

    ; --- 3. Add Column Offset ---
    ; Final Address = Base + RowOffset + worldX
    movzx ebx, worldX
    add esi, ebx
    
    ; --- 4. Return Character ---
    mov al, [esi]            ; Put the character in AL to return it

    pop edx
    pop ebx
    pop esi
    ret
GetTile ENDP























; ==========================================================
;   NEW PROCEDURES FOR MENU & PAUSE
; ==========================================================

ShowTitleScreen PROC
    ; 1. Start Music
    call PlayMenuMusic

    ; 2. Set Background to BLUE
    call Clrscr
    mov eax, yellow + (Brown * 16) ; Yellow Text on Blue BG
    call SetTextColor
    call Clrscr                   ; Clear again to fill screen with Blue

    ; --- Draw "SUPER MARIO" ASCII Art ---
    mov ebx, 5      ; Start Row

    ; Line 1 (Red)
    mov eax, lightRed + (blue * 16)
    call SetTextColor
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET titleLine1
    call WriteString
    
    inc ebx
    ; Line 2 (Yellow)
    mov eax, yellow + (blue * 16)
    call SetTextColor
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET titleLine2
    call WriteString

    inc ebx
    ; Line 3 (Green)
    mov eax, lightGreen + (blue * 16)
    call SetTextColor
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET titleLine3
    call WriteString

    inc ebx
    ; Line 4 (Cyan)
    mov eax, lightCyan + (blue * 16)
    call SetTextColor
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET titleLine4
    call WriteString

    inc ebx
    ; Line 5 (Magenta)
    mov eax, lightMagenta + (blue * 16)
    call SetTextColor
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET titleLine5
    call WriteString

    ; --- Draw Mario Face (White) ---
    mov eax, white + (blue * 16)
    call SetTextColor
    add ebx, 2      ; Skip 2 lines

    ; Loop to draw 5 lines of Mario face
    mov ecx, 5
    mov esi, OFFSET marioLine1 ; Start of face array logic needs manual handling usually, 
                               ; but since you have variables marioLine1..5:
    
    ; Mario Line 1
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET marioLine1
    call WriteString
    inc ebx

    ; Mario Line 2
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET marioLine2
    call WriteString
    inc ebx

    ; Mario Line 3
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET marioLine3
    call WriteString
    inc ebx

    ; Mario Line 4
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET marioLine4
    call WriteString
    inc ebx

    ; Mario Line 5
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET marioLine5
    call WriteString

    ; --- Student ID ---
    add ebx, 3
    mov dh, bl
    mov dl, 45
    call Gotoxy
    mov eax, white + (blue * 16)
    call SetTextColor
    mov edx, OFFSET studentInfo
    call WriteString

    ; --- Press Key ---
    add ebx, 2
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov eax,  yellow + (blue * 16) ; Blinking Yellow?
    call SetTextColor
    mov edx, OFFSET pressKeyMsg
    call WriteString
    
    call ReadChar
    ret
ShowTitleScreen ENDP











ShowMainMenu PROC
    ; Set Blue Background for Menu too
    mov eax, white + (blue * 16)
    call SetTextColor
    call Clrscr

    mov ebx, 10      ; Start Row

    ; Title
    mov dh, bl
    mov dl, 48
    call Gotoxy
    mov eax, yellow + (blue * 16) ; Yellow Title
    call SetTextColor
    mov edx, OFFSET menuTitle
    call WriteString

    add ebx, 2
    mov eax, white + (blue * 16)  ; White Options
    call SetTextColor

    ; Options 1-5
    mov dh, bl
    mov dl, 48
    call Gotoxy
    mov edx, OFFSET opt1
    call WriteString

    inc ebx
    mov dh, bl
    mov dl, 48
    call Gotoxy
    mov edx, OFFSET opt2
    call WriteString

    inc ebx
    mov dh, bl
    mov dl, 48
    call Gotoxy
    mov edx, OFFSET opt3
    call WriteString

    inc ebx
    mov dh, bl
    mov dl, 48
    call Gotoxy
    mov edx, OFFSET opt4
    call WriteString

    inc ebx
    mov dh, bl
    mov dl, 48
    call Gotoxy
    mov edx, OFFSET opt5 ; High Scores option
    call WriteString

    ; Select Msg
    add ebx, 2
    mov dh, bl
    mov dl, 48
    call Gotoxy
    mov eax, lightCyan + (blue * 16)
    call SetTextColor
    mov edx, OFFSET selectMsg
    call WriteString

GetMenuInput:
    call ReadChar
    
    cmp al, '1'
    je ReturnMenu
    cmp al, '4'
    je ReturnMenu
    cmp al, '2'
    je ShowInst
    cmp al, '3'
    je ShowCreds
    cmp al, '5'
    je ShowScoresAction
    
    jmp GetMenuInput

ShowScoresAction:
    call ShowHighScoresScreen
    jmp ShowMainMenu

ShowInst:
    ; (Keep your existing ShowInst logic, just remember to fix colors if you want)
    call Clrscr
    mov ebx, 10
    mov dh, bl
    mov dl, 45
    call Gotoxy
    mov edx, OFFSET instLine1
    call WriteString
    inc ebx
    mov dh, bl
    mov dl, 45
    call Gotoxy
    mov edx, OFFSET instLine2
    call WriteString
    inc ebx
    mov dh, bl
    mov dl, 45
    call Gotoxy
    mov edx, OFFSET instLine3
    call WriteString
    inc ebx
    mov dh, bl
    mov dl, 45
    call Gotoxy
    mov edx, OFFSET instLine4
    call WriteString
    add ebx, 2
    mov dh, bl
    mov dl, 45
    call Gotoxy
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call ReadChar
    jmp ShowMainMenu 

ShowCreds:
    call Clrscr
    mov ebx, 10
    mov dh, bl
    mov dl, 42      
    call Gotoxy
    mov edx, OFFSET creditLine1
    call WriteString
    inc ebx
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET creditLine2
    call WriteString
    inc ebx
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET creditLine3
    call WriteString
    add ebx, 2
    mov dh, bl
    mov dl, 42
    call Gotoxy
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call ReadChar
    jmp ShowMainMenu 

ReturnMenu:
    ret
ShowMainMenu ENDP

PauseGame PROC
    ; --- 1. Draw "GAME PAUSED" Box (Centered) ---
    mov dl, 54          ; (120 - 11) / 2 = ~54
    mov dh, 10          ; Center-ish height
    call Gotoxy
    
    mov eax, white + (red * 16) ; Red Background
    call SetTextColor
    mov edx, OFFSET pauseMsg
    call WriteString
    
    ; --- 2. Draw Options (Normal Color) ---
    mov eax, white + (black * 16)
    call SetTextColor

    ; Option 1: Resume
    mov dl, 53          ; (120 - 14) / 2 = ~53
    mov dh, 12
    call Gotoxy
    mov edx, OFFSET pauseOpt1
    call WriteString

    ; Option 2: Exit
    mov dl, 53          ; (120 - 15) / 2 = ~53
    mov dh, 13
    call Gotoxy
    mov edx, OFFSET pauseOpt2
    call WriteString

PauseInputLoop:
    call ReadChar       ; Wait for input
    
    ; --- Case 1: RESUME ---
    cmp al, '1'
    je ResumeAction
    
    ; --- Case 2: EXIT ---
    cmp al, '2'
    je ExitAction
    
    jmp PauseInputLoop  ; Ignore other keys

ResumeAction:
    ; Redraw level to wipe the menu off the screen
    call DrawLevel
    call DrawPlayer
    mov al, 1           ; Return 1 = Resume
    ret

ExitAction:
    ; No need to redraw, Main Menu will Clear Screen
    mov al, 2           ; Return 2 = Exit
    ret
PauseGame ENDP

DrawHUD PROC
    push eax
    push edx
    push esi
    
    mov eax, white + (black * 16) 
    call SetTextColor

    ; ===========================
    ; ROW 26: LABELS
    ; ===========================
    
    ; SCORE Label
    mov dh, 26          ; <--- IMPORTANT: Reload Row
    mov dl, 2           ; Column
    call Gotoxy
    mov edx, OFFSET hudLabelScore
    call WriteString
    
    ; COINS Label
    mov dh, 26          ; <--- IMPORTANT: Reload Row
    mov dl, 25
    call Gotoxy
    mov edx, OFFSET hudLabelCoins
    call WriteString
    
    ; WORLD Label
    mov dh, 26          ; <--- IMPORTANT: Reload Row
    mov dl, 50
    call Gotoxy
    mov edx, OFFSET hudLabelWorld
    call WriteString
    
    ; TIME Label
    mov dh, 26          ; <--- IMPORTANT: Reload Row
    mov dl, 75
    call Gotoxy
    mov edx, OFFSET hudLabelTime
    call WriteString

    ; LIVES Label
    mov dh, 26          ; <--- IMPORTANT: Reload Row
    mov dl, 100
    call Gotoxy
    mov edx, OFFSET hudLabelLives
    call WriteString

    ; ===========================
    ; ROW 27: VALUES
    ; ===========================
    
    ; SCORE Value
    mov dh, 27          ; <--- IMPORTANT: Reload Row
    mov dl, 2
    call Gotoxy
    mov eax, score
    call WriteDec       ; WriteDec removes the "+" sign
    
    ; COINS Value
    mov dh, 27          ; <--- IMPORTANT: Reload Row
    mov dl, 25
    call Gotoxy
    movzx eax, gameCoins
    call WriteDec       ; WriteDec removes the "+" sign
    
    ; WORLD Value
    mov dh, 27          ; <--- IMPORTANT: Reload Row
    mov dl, 50
    call Gotoxy
    mov edx, OFFSET hudStrWorld
    call WriteString
    ; Print Level Number
    movzx eax, currentLevelNum
    call WriteDec
    
    ; TIME Value
    mov dh, 27          ; <--- IMPORTANT: Reload Row
    mov dl, 75
    call Gotoxy
    mov eax, gameTime
    call WriteDec       ; WriteDec removes the "+" sign

    ; LIVES Value
    mov dh, 27          ; <--- IMPORTANT: Reload Row
    mov dl, 100
    call Gotoxy
    movzx eax, gameLives
    call WriteDec       ; WriteDec removes the "+" sign

    pop esi
    pop edx
    pop eax
    ret
DrawHUD ENDP

SetupConsole PROC
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE
    mov outHandle, eax

    ; 1. Set the Buffer to be large (120x40)
    INVOKE SetConsoleScreenBufferSize, outHandle, bufferSize

    ; 2. Resize the actual Window to match (120x40)
    INVOKE SetConsoleWindowInfo, outHandle, 1, ADDR windowRect
    ret
SetupConsole ENDP

DrawEnemies PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov esi, OFFSET enemies
    mov ecx, numEnemies

DrawEnemyLoop:
    ; 1. Check if Alive
    cmp (Enemy PTR [esi]).active, 1
    jne NextEnemy

    ; 2. Calculate Screen X
    movzx eax, (Enemy PTR [esi]).x
    movzx ebx, cameraX
    sub eax, ebx
    
    ; 3. Check Visibility
    cmp eax, 0
    jl NextEnemy        
    cmp eax, 119
    jg NextEnemy        

    ; 4. Setup Cursor
    mov dl, al          ; DL = Screen X
    mov dh, (Enemy PTR [esi]).y
    call Gotoxy

    ; 5. Determine Type and Draw
    cmp (Enemy PTR [esi]).eType, 1
    je DrawTurtle

    ; --- DRAW GOOMBA ---
    mov eax, white + (magenta * 16) ; Red Background
    call SetTextColor
    mov al, 'O'         
    call WriteChar
    jmp NextEnemy

DrawTurtle:
    cmp (Enemy PTR [esi]).state, 1
    je DrawShell

    ; --- DRAW WALKING TURTLE ---
    mov eax, white + (green * 16)   ; Green Background
    call SetTextColor
    mov al, 'T'
    call WriteChar
    jmp NextEnemy

DrawShell:
    ; --- DRAW SHELL (Stunned) ---
    mov eax, black + (yellow * 16)  ; Yellow Background
    call SetTextColor
    mov al, '@'         
    call WriteChar

NextEnemy:
    add esi, TYPE Enemy
    loop DrawEnemyLoop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
DrawEnemies ENDP










UpdateEnemies PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    call EraseEnemies

    ; --- Global Speed Control ---
    inc enemySpeedCounter
    cmp enemySpeedCounter, 3
    jl CheckCollisionsOnly      
    mov enemySpeedCounter, 0

    mov esi, OFFSET enemies
    mov ecx, numEnemies

UpdateLoop:
    cmp (Enemy PTR [esi]).active, 1
    jne ContinueLoop

    ; ==============================
    ;   TURTLE SHELL LOGIC
    ; ==============================
    cmp (Enemy PTR [esi]).state, 1
    jne NormalMovement
    
    dec (Enemy PTR [esi]).timer
    jnz CheckCollisionInline    ; Skip movement if stunned
    
    ; Wake up
    mov (Enemy PTR [esi]).state, 0
    jmp NormalMovement

    ; ==============================
    ;   NORMAL MOVEMENT
    ; ==============================
NormalMovement:
    cmp (Enemy PTR [esi]).dir, 0
    je TryMoveLeft
    jmp TryMoveRight

TryMoveLeft:
    mov al, (Enemy PTR [esi]).x
    dec al
    mov worldX, al              
    mov bl, (Enemy PTR [esi]).y
    mov worldY, bl
    call GetTile                
    cmp al, '|'
    je FlipDirection
    cmp al, '!'
    je FlipDirection
    cmp al, '='
    je FlipDirection
    dec (Enemy PTR [esi]).x      
    jmp CheckCollisionInline

TryMoveRight:
    mov al, (Enemy PTR [esi]).x
    inc al
    mov worldX, al
    mov bl, (Enemy PTR [esi]).y
    mov worldY, bl
    call GetTile
    cmp al, '|'
    je FlipDirection
    cmp al, '!'
    je FlipDirection
    cmp al, '='
    je FlipDirection
    inc (Enemy PTR [esi]).x      
    jmp CheckCollisionInline

FlipDirection:
    xor (Enemy PTR [esi]).dir, 1 

    ; ======================================================
    ;   COLLISION LOGIC (IMPROVED LENIENCY)
    ; ======================================================
CheckCollisionInline:
    ; --- 1. X Check (WIDER HITBOX) ---
    ; Increased leniency from 2 to 4 pixels
    
    movzx eax, xPos
    add al, cameraX     
    mov bl, (Enemy PTR [esi]).x
    sub al, bl          
    
    cmp al, -4          ; <--- WAS -2 (Now allows landing if slightly left)
    jl ContinueLoop     
    cmp al, 4           ; <--- WAS 2  (Now allows landing if slightly right)
    jg ContinueLoop     

    ; --- 2. Y Check (Vertical Context) ---
    ; diff = MarioPrevY - EnemyY
    
    mov al, yPrev       
    sub al, (Enemy PTR [esi]).y
    
    ; Logic Table:
    ; diff <= -4  : Mario is high above (Safety for platforms) -> Ignore
    ; diff == -3 to 0 : Mario is landing on top -> Squash
    ; diff >= 1   : Mario is inside/below -> Kill
    
    cmp al, -4          
    jl ContinueLoop     ; SAFE: Mario is high above on a platform
    
    cmp al, 0           
    jg JumpToKill       ; KILL: Mario is physically inside or below
    
    ; If we are here, al is -3, -2, -1, or 0. This is the "Sweet Spot".
    jmp JumpToSquash

JumpToSquash:
    jmp SquashEnemyHandler
JumpToKill:
    call KillMarioPROC    ; <--- Now we CALL the function
    jmp EndUpdateEnemies  ; Then finish the loop

ContinueLoop:
    add esi, TYPE Enemy
    dec ecx             
    cmp ecx, 0
    jg UpdateLoop
    jmp EndUpdateEnemies

; =============================================
;   SQUASH HANDLER
; =============================================
SquashEnemyHandler:
    ; 1. Bounce Mario
    mov velocityY, -3
    mov isJumping, 1
    add score, 50

    ; 2. Check Type
    cmp (Enemy PTR [esi]).eType, 1
    je HandleTurtleSquash

    ; -- Goomba Logic (Instant Death) --
    mov (Enemy PTR [esi]).active, 0 
    jmp ContinueLoop

    ; -- Turtle Logic --
HandleTurtleSquash:
    cmp (Enemy PTR [esi]).state, 1
    je KillTurtle
    
    ; Stun (1st Hit)
    mov (Enemy PTR [esi]).state, 1
    mov (Enemy PTR [esi]).timer, 100 ; Stunned longer (approx 5 sec)
    
    ; Push Turtle slightly to avoid instant re-collision loop
    ; (Optional tweak to prevent getting stuck inside)
    jmp ContinueLoop

KillTurtle:
    ; Kill (2nd Hit)
    mov (Enemy PTR [esi]).active, 0
    add score, 100
    jmp ContinueLoop

; =============================================
;   KILL MARIO HANDLER
; =============================================
KillMarioHandler:

; --- INVINCIBILITY CHECK ---
    cmp isInvincible, 1
    je EndUpdateEnemies ; Ignore collision (Safety)

    dec gameLives
    cmp gameLives, 0
    je ResetGameFull
    dec gameLives
    cmp gameLives, 0
    je ResetGameFull    
    
    mov xPos, 20        
    mov yPos, 10        
    mov velocityY, 0    
    
    call DrawLevel      
    call DrawHUD        
    call DrawPlayer     
    jmp EndUpdateEnemies 

ResetGameFull:
    call ShowGameOver
    mov gameLives, 5
    mov score, 0
    mov cameraX, 0
    mov xPos, 40
    mov yPos, 10
    call DrawLevel
    call DrawHUD
    jmp EndUpdateEnemies

; =============================================
;   NON-MOVING COLLISION CHECK (Idle Check)
; =============================================
CheckCollisionsOnly:
    mov esi, OFFSET enemies
    mov ecx, numEnemies
CollisionLoopOnly:
    cmp (Enemy PTR [esi]).active, 1
    jne NextColOnly
    
    ; X Check (Updated Leniency)
    movzx eax, xPos
    add al, cameraX
    mov bl, (Enemy PTR [esi]).x
    sub al, bl
    cmp al, -2          ; <--- UPDATED
    jl NextColOnly
    cmp al, 2           ; <--- UPDATED
    jg NextColOnly
    
    ; Y Check
    mov al, yPrev
    sub al, (Enemy PTR [esi]).y
    
    cmp al, -2
    jl NextColOnly      ; Safe (above)
    cmp al, 0
    jg JumpToKill       ; Kill (inside)
    
    jmp JumpToSquash    ; Squash
    
NextColOnly:
    add esi, TYPE Enemy
    dec ecx
    cmp ecx, 0
    jg CollisionLoopOnly

EndUpdateEnemies:
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
UpdateEnemies ENDP













EraseEnemies PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov esi, OFFSET enemies
    mov ecx, numEnemies

EraseLoop:
    ; 1. Check if Alive
    cmp (Enemy PTR [esi]).active, 1
    jne NextErase

    ; 2. Calculate Screen X
    movzx eax, (Enemy PTR [esi]).x
    movzx ebx, cameraX
    sub eax, ebx
    
    ; 3. Check Visibility
    cmp eax, 0
    jl NextErase
    cmp eax, 119
    jg NextErase

    ; 4. Erase (Draw Blue Space)
    mov dl, al          ; Screen X
    mov dh, (Enemy PTR [esi]).y
    call Gotoxy
    
    mov eax, 1 + (1 * 16) ; Blue Background (Sky)
    call SetTextColor
    mov al, ' '           ; Space
    call WriteChar

NextErase:
    add esi, TYPE Enemy
    loop EraseLoop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
EraseEnemies ENDP









ShowGameOver PROC
    call Clrscr
    
    ; --- 1. Draw "YOU DIED" (Red Background) ---
    mov dl, 56          ; Centered (120/2 - 4)
    mov dh, 12          ; Middle Row
    call Gotoxy
    
    mov eax, white + (red * 16) 
    call SetTextColor
    mov edx, OFFSET gameOverStr
    call WriteString

    ; --- 2. Draw Final Score ---
    mov dl, 52          ; Centered-ish
    mov dh, 14
    call Gotoxy
    
    mov eax, white + (black * 16)
    call SetTextColor
    mov edx, OFFSET finalScoreStr
    call WriteString
    
    mov eax, score
    call WriteDec

    ; --- 3. SAVE HIGH SCORE ---
    call UpdateHighScores   ; <--- CRITICAL ADDITION

    ; --- 4. Draw Restart Message ---
    mov dl, 45
    mov dh, 16
    call Gotoxy
    mov edx, OFFSET restartMsg
    call WriteString

    ; --- 5. Wait for Key ---
    call ReadChar       ; Pauses until user presses a key
    
    ; Restore colors
    mov eax, white + (black * 16)
    call SetTextColor
    ret
ShowGameOver ENDP



ShowLevelComplete PROC
    call Clrscr
    
    ; --- 1. CALCULATE TIME BONUS ---
    ; Score += (Time * 10)
    mov eax, gameTime
    mov ebx, 10
    mul ebx             ; EAX = Time * 10
    mov ecx, score
    add ecx, eax        ; ECX = OldScore + Bonus
    mov score, ecx        

    ; --- 2. SAVE HIGH SCORE ---
    call UpdateHighScores   ; <--- CRITICAL ADDITION

    ; --- 3. Draw "LEVEL COMPLETE" (Green Background) ---
    mov dl, 52          ; Centered
    mov dh, 10
    call Gotoxy
    
    mov eax, white + (green * 16) 
    call SetTextColor
    mov edx, OFFSET levelCompleteStr
    call WriteString

    ; --- 4. Draw Time Bonus ---
    mov dl, 50
    mov dh, 12
    call Gotoxy
    mov eax, white + (black * 16) 
    call SetTextColor
    mov edx, OFFSET timeBonusStr
    call WriteString
    
    mov eax, gameTime
    call WriteDec

    ; --- 5. Draw Total Score ---
    mov dl, 50
    mov dh, 13
    call Gotoxy
    mov edx, OFFSET totalScoreStr
    call WriteString
    
    mov eax, score      ; The final score is now in 'score' variable
    call WriteDec

    ; --- 6. Restart Message ---
    mov dl, 45
    mov dh, 16
    call Gotoxy
    mov edx, OFFSET restartMsg 
    call WriteString

    ; --- 7. Wait and Exit ---
    call ReadChar       
    ret                 ; Returns to caller
ShowLevelComplete ENDP


















CheckFlagCollision PROC
    push eax
    push ebx
    push esi
    push edx

    ; 1. Calculate Address for FEET
    movzx eax, yPos         
    mov ebx, 241            
    mul ebx                 ; y * 241
    
    movzx ebx, xPos         
    add eax, ebx            ; + x
    
    movzx ebx, cameraX      
    add eax, ebx            ; + camera
    
    mov esi, currentLevelPtr
    add esi, eax            

    ; --- 2. FEET CHECK (Horizontal Hitbox) ---
    ; Check Left (-1), Center (0), and Right (+1)
    ; This stops Mario from "skipping" the flag at speed 3
    cmp byte ptr [esi], '1'    
    je TriggerWin
    cmp byte ptr [esi+1], '1'  
    je TriggerWin
    cmp byte ptr [esi-1], '1'  ; <--- CRITICAL ADDITION
    je TriggerWin

    ; --- 3. HEAD CHECK (Vertical Hitbox) ---
    ; If Mario jumps, his feet might miss, but his head hits.
    ; Move pointer UP one row (subtract 241)
    sub esi, 241               
    
    cmp byte ptr [esi], '1'    
    je TriggerWin
    cmp byte ptr [esi+1], '1'  
    je TriggerWin
    cmp byte ptr [esi-1], '1'  ; <--- CRITICAL ADDITION
    je TriggerWin

    jmp NoWin

TriggerWin:
    pop edx
    pop esi
    pop ebx
    pop eax
    mov al, 1   ; Return 1 means WIN
    ret

NoWin:
    pop edx
    pop esi
    pop ebx
    pop eax
    mov al, 0   ; Return 0 means Keep Playing
    ret
CheckFlagCollision ENDP













GetBackgroundColor PROC
    push esi
    push edx
    push edi
    push ecx
    push ebx

    mov eax, 241
    mul ecx                  
    mov esi, currentLevelPtr
    add esi, eax             

    xor edx, edx             
    mov edi, 0               

ScanLoop:
    cmp edi, ebx             
    je FoundState            

    mov al, [esi + edi]      
    cmp al, '!'
    je TogglePipe
    cmp al, '('
    je EnterCloud
    cmp al, ')'
    je ExitCloud
    jmp NextChar

TogglePipe:
    cmp edx, 2
    je LeavePipe
    mov edx, 2
    jmp NextChar
LeavePipe:
    mov edx, 0
    jmp NextChar
EnterCloud:
    mov edx, 1
    jmp NextChar
ExitCloud:
    mov edx, 0
    jmp NextChar

NextChar:
    inc edi
    jmp ScanLoop

FoundState:
    mov al, [esi + ebx]      
    
    cmp al, '='
    je RetGround
    cmp al, '|'
    je RetGround
    cmp al, '_'
    je RetGround
    cmp al, '!'
    je RetPipeWall
    cmp al, '^'
    je RetPipeTop
    cmp al, '~'          ; <--- CHECK FOR LAVA
    je RetLava           ; <--- NEW HANDLER
    cmp al, '1'
    je RetPole
    
    ; --- ADD MUSHROOM HERE ---
    cmp al, '%'
    je RetMushroom
    ; -------------------------
    cmp al, '&'          ; <--- ADD THIS
    je RetFlower
    cmp al, '-'
    je RetCloudChar
    cmp al, '('
    je RetCloudChar
    cmp al, ')'
    je RetCloudChar

    cmp edx, 2
    je HandleInsidePipe      
    cmp edx, 1
    je HandleInsideCloud     
    
    cmp al, '0'
    je RetCoinBlue
    jmp RetSky

HandleInsidePipe:
    cmp al, ' '
    je RetSolidGreen
    cmp al, '0'
    je RetCoinGreen          
    jmp RetSolidGreen        

HandleInsideCloud:
    cmp al, ' '
    je RetSolidWhite
    cmp al, '0'
    je RetCoinWhite
    jmp RetCloudChar         

RetGround:
    mov eax, 15 + (4 * 16)   
    jmp DoneColor
RetPipeWall:
    mov eax, 0 + (2 * 16)    
    jmp DoneColor
RetPipeTop:
    mov eax, 0 + (2 * 16)    
    jmp DoneColor
RetPole:
    mov eax, 0 + (2 * 16)    
    jmp DoneColor
RetFlower:
    mov eax, brown + (brown * 16) ; Light Red Text on White BG
    jmp DoneColor
RetLava:

    mov eax, 14 + (4 * 16)   ; Yellow Text on Red Background (Hot!)
    jmp DoneColor

; --- ADD MUSHROOM COLOR ---
RetMushroom:
    mov eax, 12 + (15 * 16) ; Red Text (12) on White BG (15)
    jmp DoneColor
; --------------------------

RetSky:
    mov eax, 1 + (1 * 16)    
    jmp DoneColor
RetCoinBlue:
    mov eax, 14 + (1 * 16)   
    jmp DoneColor
RetCloudChar:
    mov eax, 15 + (1 * 16)   
    jmp DoneColor
RetSolidGreen:
    mov eax, 2 + (2 * 16)    
    jmp DoneColor
RetCoinGreen:
    mov eax, 14 + (2 * 16)   
    jmp DoneColor
RetSolidWhite:
    mov eax, 15 + (15 * 16)  
    jmp DoneColor
RetCoinWhite:
    mov eax, 14 + (15 * 16)  
    jmp DoneColor

DoneColor:
    pop ebx
    pop ecx
    pop edi
    pop edx
    pop esi
    ret
GetBackgroundColor ENDP

SetupLevel3 PROC
    mov currentLevelPtr, OFFSET level3Layout
    mov currentLevelNum, 3
    mov xPos, 5
    mov yPos, 20
    mov cameraX, 0
    mov velocityY, 0
    mov isJumping, 0

    ; --- ACTIVATE BOSS ---
    mov bossActive, 1
    mov bossHealth, 10
    mov bossX, 120       ; Start in Middle
    mov bossDirY, 0      ; Start moving Up
    mov bossTimer, 0
    
    ret
SetupLevel3 ENDP






KillMarioPROC PROC
    ; --- 1. CHECK INVINCIBILITY ---
    cmp isInvincible, 1
    je ExitKill             ; If invincible, ignore death

    ; --- 2. LOSE A LIFE ---
    dec gameLives
    cmp gameLives, 0
    je TriggerGameOver      ; If 0 lives, go to Game Over

    ; --- 3. RESET POSITION (Respawn) ---
    mov xPos, 20
    mov yPos, 10
    mov velocityY, 0
    
    ; Redraw the screen immediately
    call DrawLevel
    call DrawHUD
    ;call DrawStaticPlatforms
    call DrawPlayer
    
    ; Small delay to let player realize they died
    mov eax, 500
    call Delay
    ret

TriggerGameOver:
    call ShowGameOver
    ; Reset Game Variables
    mov gameLives, 5
    mov score, 0
    mov cameraX, 0
    mov xPos, 20
    mov yPos, 10
    mov isInvincible, 0
    
    call DrawLevel
    call DrawHUD
    ret

ExitKill:
    ret
KillMarioPROC ENDP




DrawBoss PROC
    cmp bossActive, 0
    je RetDrawBoss

    ; Calculate Screen X
    movzx eax, bossX
    movzx ebx, cameraX
    sub eax, ebx
    
    ; Bounds Check
    cmp eax, 0
    jl RetDrawBoss
    cmp eax, 115
    jg RetDrawBoss

    mov dl, al          ; DL = Screen X
    mov dh, bossY       ; DH = Boss Y
    
    ; --- DRAW HEALTH BAR (Above Head) ---
    push edx            ; Save Boss Body Position
    sub dh, 2           ; Move 2 rows up
    call Gotoxy
    mov eax, lightRed + (black * 16)
    call SetTextColor
    
    movzx ecx, bossHealth
    cmp ecx, 0
    je SkipBar
DrawBarLoop:
    mov al, '_'         ; Thin Bar
    call WriteChar
    loop DrawBarLoop
SkipBar:
    pop edx             ; Restore Boss Body Position

    ; --- DRAW BOSS BODY ---
    call Gotoxy         ; Move back to Body Pos
    mov eax, yellow + (red * 16)
    call SetTextColor
    mov al, 'B'         
    call WriteChar

RetDrawBoss:
    ret
DrawBoss ENDP






UpdateBoss PROC
    cmp bossActive, 0
    je RetUpdateBoss

    ; --- 1. ERASE FIRST ---
    call EraseBoss

    ; ==========================================
    ;   A. MOVEMENT: VERTICAL (Ghost Float)
    ; ==========================================
    inc bossMoveTimer
    cmp bossMoveTimer, 3
    jl CheckRetreat     ; Skip vertical, check horizontal
    mov bossMoveTimer, 0

    cmp bossDirY, 0
    je FloatUp
FloatDown:
    inc bossY
    cmp bossY, 22
    jl CheckRetreat
    mov bossDirY, 0     
    jmp CheckRetreat
FloatUp:
    dec bossY
    cmp bossY, 12
    jg CheckRetreat
    mov bossDirY, 1     

    ; ==========================================
    ;   B. MOVEMENT: RETREAT (The Fix)
    ; ==========================================
; ==========================================
    ;   B. MOVEMENT: RETREAT (FIXED)
    ; ==========================================
CheckRetreat:
    ; 1. Get Mario World X (Safe 16-bit)
    movzx ax, xPos
    movzx bx, cameraX
    add ax, bx          ; AX = Mario World X
    
    ; 2. Get Boss X
    movzx bx, bossX     ; BX = Boss X

    ; 3. Calculate Distance (Boss - Mario)
    sub bx, ax          ; BX = Distance
    
    ; 4. Check if Mario is "Behind" the boss
    ; If BX wraps around to a huge number (like 65000), Mario is to the right
    cmp bx, 300         
    ja ForceRetreat     ; Unsigned check (Above) handles negative wrap-around
    
    ; 5. Check if Mario is "Too Close" 
    cmp bx, 30          
    ja BossAttackLogic  ; <--- CHANGED 'jg' to 'ja' (Jump if Above)
                        ; If Distance > 60 (unsigned), he feels safe. Stand still.

ForceRetreat:
    ; 6. Check Pin Limit (Flag Area)
    cmp bossX, 220
    jae BossAttackLogic ; <--- CHANGED 'jge' to 'jae' (Jump if Above or Equal)
                        ; Unsigned check fixes the "120 vs 210" bug.

    ; 7. DO THE MOVE
    inc bossX           ; Retreat Right       ; Retreat Right

    ; ==========================================
    ;   C. ATTACK LOGIC
    ; ==========================================
BossAttackLogic:
    inc bossTimer
    cmp bossTimer, 40   
    jl CheckCollisions
    
    mov bossTimer, 0
    
    ; Spawn Fireball
    mov dl, bossX
    dec dl              
    mov dh, bossY
    dec dh              
    mov al, 0           ; Left
    mov ah,1
    call SpawnFireball

    ; ==========================================
    ;   D. COLLISION CHECKS
    ; ==========================================
CheckCollisions:
    movzx eax, xPos
    add al, cameraX
    sub al, bossX       
    
    ; X Hitbox
    cmp al, -2
    jl RetUpdateBoss
    cmp al, 2
    jg RetUpdateBoss

    ; Y Hitbox
    mov al, yPrev
    sub al, bossY
    cmp al, -4
    jl RetUpdateBoss    
    cmp al, 0
    jg HurtMario        

    ; Velocity Check
    cmp velocityY, 0
    jle HurtMario

    ; HIT BOSS
    dec bossHealth
    mov velocityY, -4   
    cmp bossHealth, 0
    jg RetUpdateBoss
    
    ; BOSS DEAD
    mov bossActive, 0
    add score, 100
    jmp RetUpdateBoss

HurtMario:
    call KillMarioPROC

RetUpdateBoss:
    ret
UpdateBoss ENDP









SpawnFireball PROC
    ; Inputs: DL = X, DH = Y, AL = Direction, AH = Owner
    push esi
    push ecx
    
    mov esi, OFFSET fireballs
    mov ecx, 5
FindSlot:
    cmp (Fireball PTR [esi]).active, 0
    je FoundSlot
    add esi, TYPE Fireball
    loop FindSlot
    jmp ExitSpawn

FoundSlot:
    mov (Fireball PTR [esi]).active, 1
    mov (Fireball PTR [esi]).x, dl
    mov (Fireball PTR [esi]).y, dh
    mov (Fireball PTR [esi]).dir, al
    mov (Fireball PTR [esi]).owner, ah  ; <--- SAVE OWNER HERE

ExitSpawn:
    pop ecx
    pop esi
    ret
SpawnFireball ENDP

UpdateFireballs PROC
    push esi
    push ecx
    push edi
    push ebx
    
    call EraseFireballs

    mov esi, OFFSET fireballs
    mov ecx, 5

FireLoop:
    cmp (Fireball PTR [esi]).active, 0
    jne ProcessFire
    jmp NextFire

ProcessFire:
    ; --- MOVEMENT ---
    cmp (Fireball PTR [esi]).dir, 1
    je FireRight
    dec (Fireball PTR [esi]).x      ; Left Speed 2
    dec (Fireball PTR [esi]).x      
    jmp CheckOwner
FireRight:
    inc (Fireball PTR [esi]).x      ; Right Speed 2
    inc (Fireball PTR [esi]).x

CheckOwner:
    cmp (Fireball PTR [esi]).owner, 0
    je CheckPlayerFire   ; Player shot -> Check Boss AND Enemies
    jmp CheckHitMario    ; Enemy shot -> Check Mario

    ; ==================================
    ;   PLAYER FIRE LOGIC
    ; ==================================
CheckPlayerFire:
    ; --- 1. CHECK BOSS COLLISION ---
    cmp bossActive, 0    
    je CheckEnemiesLoop  ; Boss dead? Check normal enemies
    
    ; Check X Distance vs Boss
    movzx eax, (Fireball PTR [esi]).x
    sub al, bossX        
    cmp al, -4
    jl CheckEnemiesLoop
    cmp al, 4
    jg CheckEnemiesLoop
    
    ; Check Y Distance vs Boss
    mov al, (Fireball PTR [esi]).y
    sub al, bossY
    cmp al, -4
    jl CheckEnemiesLoop
    cmp al, 1
    jg CheckEnemiesLoop
    
    ; BOSS HIT!
    dec bossHealth
    mov (Fireball PTR [esi]).active, 0 ; Kill Fireball
    
    cmp bossHealth, 0
    jg NextFire          
    
    mov bossActive, 0    ; Boss Dead
    add score, 1000
    jmp NextFire

    ; --- 2. CHECK NORMAL ENEMIES ---
CheckEnemiesLoop:
    ; Save Fireball Loop Counter (ECX) & Pointer (ESI)
    push ecx
    push esi
    
    mov edi, OFFSET enemies
    mov ecx, numEnemies

EnemyColLoop:
    cmp (Enemy PTR [edi]).active, 1
    jne NextEnemyCheck

    ; Check X Distance
    movzx eax, (Fireball PTR [esi]).x
    sub al, (Enemy PTR [edi]).x
    
    cmp al, -2
    jl NextEnemyCheck
    cmp al, 2
    jg NextEnemyCheck
    
    ; Check Y Distance
    mov al, (Fireball PTR [esi]).y
    sub al, (Enemy PTR [edi]).y
    cmp al, -2
    jl NextEnemyCheck
    cmp al, 2
    jg NextEnemyCheck

    ; --- ENEMY HIT! ---
    mov (Enemy PTR [edi]).active, 0    ; Kill Enemy
    add score, 100                     ; Score
    
    ; Kill Fireball (ESI is still fireball pointer)
    mov (Fireball PTR [esi]).active, 0 
    
    ; Exit Loop immediately (1 fireball kills 1 enemy)
    pop esi
    pop ecx
    jmp NextFire

NextEnemyCheck:
    add edi, TYPE Enemy
    dec ecx
    jnz EnemyColLoop

    ; Restore if no hit
    pop esi
    pop ecx
    jmp CheckBounds

    ; ==================================
    ;   ENEMY FIRE vs MARIO
    ; ==================================
CheckHitMario:
    movzx eax, xPos
    add al, cameraX
    sub al, (Fireball PTR [esi]).x
    
    cmp al, -2
    jl CheckBounds
    cmp al, 2
    jg CheckBounds
    
    mov al, yPos
    cmp al, (Fireball PTR [esi]).y
    jne CheckBounds
    
    ; Hit Mario
    call KillMarioPROC
    mov (Fireball PTR [esi]).active, 0

CheckBounds:
    ; Bounds Check
    cmp (Fireball PTR [esi]).x, 0
    je KillFire
    cmp (Fireball PTR [esi]).x, 230
    ja KillFire
    jmp NextFire

KillFire:
    mov (Fireball PTR [esi]).active, 0

NextFire:
    add esi, TYPE Fireball
    dec ecx                 
    jnz FireLoop            

    pop ebx
    pop edi
    pop ecx
    pop esi
    ret
UpdateFireballs ENDP





DrawFireballs PROC
    push esi
    push ecx
    mov esi, OFFSET fireballs
    mov ecx, 5
DrawFireLoop:
    cmp (Fireball PTR [esi]).active, 0
    je NextDrawFire
    
    movzx eax, (Fireball PTR [esi]).x
    movzx ebx, cameraX
    sub eax, ebx
    
    cmp eax, 0
    jl NextDrawFire
    cmp eax, 119
    jg NextDrawFire
    
    mov dl, al
    mov dh, (Fireball PTR [esi]).y
    
    ; --- SAFETY CHECK (The Fix) ---
    cmp dh, 2           ; Don't draw on top 2 rows
    jl NextDrawFire
    
    call Gotoxy
    mov eax, black + (brown * 16)
    call SetTextColor
    mov al, '*'
    call WriteChar
NextDrawFire:
    add esi, TYPE Fireball
    loop DrawFireLoop
    pop ecx
    pop esi
    ret
DrawFireballs ENDP





EraseFireballs PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi

    mov esi, OFFSET fireballs
    mov ecx, 5

EraseFireLoop:
    cmp (Fireball PTR [esi]).active, 0
    je NextEraseFire

    movzx eax, (Fireball PTR [esi]).x
    movzx ebx, cameraX
    sub eax, ebx
    
    cmp eax, 0
    jl NextEraseFire
    cmp eax, 119
    jg NextEraseFire

    mov dl, al
    mov dh, (Fireball PTR [esi]).y
    
    ; --- SAFETY CHECK ---
    cmp dh, 2
    jl NextEraseFire
    
    call Gotoxy

    ; Restore Background
    push ebx
    push ecx
    movzx ebx, (Fireball PTR [esi]).x  
    movzx ecx, (Fireball PTR [esi]).y  
    call GetBackgroundColor            
    call SetTextColor
    pop ecx
    pop ebx

    mov al, ' '
    call WriteChar

NextEraseFire:
    add esi, TYPE Fireball
    loop EraseFireLoop

    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
EraseFireballs ENDP







EraseBoss PROC
    cmp bossActive, 0
    je RetEraseBoss

    ; Calculate Screen X
    movzx eax, bossX
    movzx ebx, cameraX
    sub eax, ebx
    
    cmp eax, 0
    jl RetEraseBoss
    cmp eax, 115
    jg RetEraseBoss

    mov dl, al          ; Screen X
    mov dh, bossY       ; Boss Y
    
    ; --- ERASE BODY ---
    call Gotoxy
    push ebx
    push ecx
    movzx ebx, bossX    
    movzx ecx, bossY    
    call GetBackgroundColor
    call SetTextColor
    pop ecx
    pop ebx
    mov al, ' '         
    call WriteChar

    ; --- ERASE HEALTH BAR (Smart Erase) ---
    sub dh, 2           ; Move to bar height
    
    ; We need to loop 10 times (bar width)
    ; and restore the background for EACH character
    mov ecx, 10
EraseBarLoop:
    call Gotoxy         ; Move to current bar char position
    
    push ebx            ; Save registers
    push ecx
    push edx

    ; Calculate World X for this specific part of the bar
    ; WorldX = ScreenX (DL) + CameraX
    movzx ebx, dl       
    add bl, cameraX
    
    movzx ecx, dh       ; World Y (is just DH)
    
    call GetBackgroundColor ; Get correct color for this tile
    call SetTextColor
    
    pop edx             ; Restore pos
    pop ecx
    pop ebx

    mov al, ' '         ; Write space with correct bg color
    call WriteChar
    
    inc dl              ; Move cursor right
    loop EraseBarLoop

RetEraseBoss:
    ret
EraseBoss ENDP




ShowHighScoresScreen PROC
    call Clrscr
    call LoadScoresFromFile
    
    ; --- DRAW TITLE ---
    mov dh, 2
    mov dl, 50
    call Gotoxy
    mov edx, OFFSET highScoreTitle
    call WriteString
    
    ; --- DRAW HEADERS ---
    mov dh, 5
    
    ; Header: NAME
    mov dl, 30
    call Gotoxy
    mov al, 'N'
    call WriteChar
    mov al, 'A'
    call WriteChar
    mov al, 'M'
    call WriteChar
    mov al, 'E'
    call WriteChar

    ; Header: SCORE
    mov dl, 60
    call Gotoxy
    mov al, 'S'
    call WriteChar
    mov al, 'C'
    call WriteChar
    mov al, 'O'
    call WriteChar
    mov al, 'R'
    call WriteChar
    mov al, 'E'
    call WriteChar

    ; --- PRINT ENTRIES ---
    mov esi, OFFSET scoresArray
    mov ecx, 5          ; Loop 5 times
    mov dh, 7           ; Start Row

PrintLoop:
    push ecx            ; Save outer loop counter
    
    ; 1. SET CURSOR FOR NAME
    mov dl, 30
    call Gotoxy
    
    ; ---------------------------------------------
    ; SAFE NAME PRINTING (The Fix)
    ; Prints up to 19 chars or until NULL (0) is found
    ; ---------------------------------------------
    push esi            ; Save current struct pointer
    mov ecx, 19         ; Max width safety
PrintNameChar:
    mov al, [esi]       ; Get character
    cmp al, 0           ; Is it null?
    je DoneName         ; If yes, stop printing name
    call WriteChar      ; Print it
    inc esi             ; Next char
    loop PrintNameChar
DoneName:
    pop esi             ; Restore struct pointer
    ; ---------------------------------------------

    ; 2. SET CURSOR FOR SCORE
    mov dl, 60
    call Gotoxy
    mov eax, (HighScoreEntry PTR [esi]).pScore
    call WriteDec
    
    ; 3. PREPARE NEXT ROW
    add esi, SIZEOF HighScoreEntry
    inc dh
    
    pop ecx             ; Restore loop counter
    dec ecx
    jnz PrintLoop
    
    ; --- WAIT FOR INPUT ---
    mov dh, 15
    mov dl, 45
    call Gotoxy
    mov edx, OFFSET pressKeyMsg
    call WriteString
    call ReadChar
    ret
ShowHighScoresScreen ENDP





UpdateHighScores PROC
    pushad
    
    ; --- STEP 1: LOAD OLD SCORES FIRST ---
    call LoadScoresFromFile
    
    mov esi, OFFSET scoresArray
    mov ecx, 5          ; Check 5 slots
    mov ebx, 0          ; Index counter

CheckLoop:
    ; Compare Current Score vs Stored Score
    mov eax, score
    cmp eax, (HighScoreEntry PTR [esi]).pScore
    jbe NextSlot        ; If current <= stored, try next slot
    
    ; --- FOUND A SPOT! Shift others down ---
    push ecx
    push esi
    
    ; Point to Last Slot
    mov edi, OFFSET scoresArray
    add edi, (SIZEOF HighScoreEntry * 4) 
    
    ; Calculate shifts needed
    mov ecx, 4
    sub ecx, ebx        
    cmp ecx, 0
    jle InsertNow       

ShiftLoop:
    ; 1. SAVE LOOP COUNTER (Critical Fix)
    push ecx        
    
    ; 2. Save Pointers
    push edi
    push esi
    
    ; 3. Setup Memory Copy
    mov esi, edi
    sub esi, SIZEOF HighScoreEntry 
    mov ecx, SIZEOF HighScoreEntry  ; This overwrites ECX!
    cld
    rep movsb                       ; Moves data, sets ECX to 0
    
    ; 4. Restore Registers
    pop esi
    pop edi
    
    ; 5. RESTORE LOOP COUNTER (Critical Fix)
    pop ecx         
    
    ; 6. Move to next slot
    sub edi, SIZEOF HighScoreEntry
    loop ShiftLoop

InsertNow:
    pop esi
    pop ecx

    ; --- INSERT NEW DATA ---
    ; 1. Copy Name
    push esi
    mov edi, esi
    mov esi, OFFSET currentPlayer
    mov ecx, 20
    rep movsb
    pop esi
    
    ; 2. Copy Score
    mov eax, score
    mov (HighScoreEntry PTR [esi]).pScore, eax
    
    ; --- STEP 3: SAVE UPDATED LIST ---
    call SaveScoresToFile
    jmp ExitUpdate

NextSlot:
    add esi, SIZEOF HighScoreEntry
    inc ebx
    loop CheckLoop

ExitUpdate:
    popad
    ret
UpdateHighScores ENDP



LoadScoresFromFile PROC
    ; 1. Try to Open File
    mov edx, OFFSET highScoreFile
    call OpenInputFile
    cmp eax, INVALID_HANDLE_VALUE
    je NoFileFound      ; If file doesn't exist, just return
    
    mov fileHandle, eax
    
    ; 2. Read Data into Array
    mov edx, OFFSET scoresArray
    mov ecx, SIZEOF scoresArray
    mov eax, fileHandle
    call ReadFromFile
    
    mov eax, fileHandle
    call CloseFile
    ret

NoFileFound:
    ret
LoadScoresFromFile ENDP





SaveScoresToFile PROC
    ; 1. Create New File (Overwrites old one)
    mov edx, OFFSET highScoreFile
    call CreateOutputFile
    mov fileHandle, eax
    
    ; 2. Write the Array
    mov edx, OFFSET scoresArray
    mov ecx, SIZEOF scoresArray
    mov eax, fileHandle
    call WriteToFile
    
    mov eax, fileHandle
    call CloseFile
    ret
SaveScoresToFile ENDP







PlayBackgroundMusic PROC
    ; Plays music in a loop
    ; Flags: SND_FILENAME | SND_ASYNC | SND_LOOP
    ; Value: 20000h | 1h | 8h = 20009h
    
    INVOKE PlaySound, ADDR bgMusicFile, NULL, 00020009h
    ret
PlayBackgroundMusic ENDP


PlayFireSound PROC
    ; Plays sound once
    ; Flags: SND_FILENAME | SND_ASYNC
    ; Value: 20000h | 1h = 20001h
    
    INVOKE PlaySound, ADDR fireSfxFile, NULL, 00020001h
    ret
PlayFireSound ENDP


StopSound PROC
    ; Playing NULL stops currently playing sounds
    INVOKE PlaySound, NULL, NULL, 0
    ret
StopSound ENDP






PlayInvincibleSound PROC
    ; Plays invincibility music (Async + Loop)
    ; Flags: 20000h (Filename) | 1h (Async) | 8h (Loop) = 20009h
    INVOKE PlaySound, ADDR invincibleSfx, NULL, 00020009h
    ret
PlayInvincibleSound ENDP



PlayMenuMusic PROC
    ; Plays Menu Music (Async + Loop)
    INVOKE PlaySound, ADDR menuMusicFile, NULL, 00020009h
    ret
PlayMenuMusic ENDP
END main