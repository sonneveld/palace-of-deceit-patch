
.8086
.no87
.dosseg

.model tiny

expected_return_for_dos_version_int EQU 14h



patch_seg_offset EQU 881h

patch_1_offset EQU 1bb4h
patch_1_check EQU 3530h
patch_1_replace EQU 'o'

patch_2_offset EQU 1d15h
patch_2_check EQU 3630h
patch_2_replace EQU 'o'


modify_mcb_name EQU 0

.code

org 100h

start:
    jmp main

a_INSTALL_CHECK        db 'sonne/podfix'       
dw_dos_21h_orig        dd 0                        
                                        

s_new_int_21h_113 proc far                

arg_2                = word ptr  4
arg_4                = word ptr  6

                pushf
                push        bp
                mov        bp, sp
                push        bx
                mov        bx, [bp+4]  ; ip
                cmp        bx, expected_return_for_dos_version_int   ;; assumed return address
                jnz        short l_do_orig_dos
                cmp        ah, 30h                ;  get the DOS verison
                jnz        short l_do_orig_dos




                push        ax
                push        cx
                push        dx
                push        si
                push        di
                push        ds
                push        es

                mov        bx, [bp+6]  ; seg001

                add        bx, patch_seg_offset
                mov        ds, bx    ;; seg008


                
                mov        bx, patch_1_offset
                mov        ax, [bx]
                cmp        ax, patch_1_check
                jnz        short l_tsr_patch_done
                mov        al, patch_1_replace
                mov        [bx], al


                mov        bx, patch_2_offset
                mov        ax, [bx]
                cmp        ax, patch_2_check
                jnz        short l_tsr_patch_done
                mov        al, patch_2_replace
                mov        [bx], al




l_tsr_patch_done:                                
                                        
                pop        es
                pop        ds
                pop        di
                pop        si
                pop        dx
                pop        cx
                pop        ax



l_do_orig_dos:                                
                                        
                pop        bx
                pop        bp
                popf
                jmp        cs:dw_dos_21h_orig
s_new_int_21h_113 endp


;; used to identify last byte of tsr
a_tsr_last_byte_163 db    0


; LOADER

aIntroMsg       db 'ÉÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ»',13,10
                db 'º      The Palace of Deceit:     ºÛ',13,10
                db 'º The Secret of Castle Lockemoer ºÛ',13,10
                db 'º          (Bugfix TSR)          ºÛ',13,10
                db 'º      Sonneveld 2024-09-17      ºÛ',13,10
                db 'ÈÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼Û',13,10
                db ' ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß',13,10
                db '$'

aAlreadyInstalledMsg    db 'Already installed!',13,10
                        db '(Remove with /r or -r)',13,10
                        db '$'
aInstalledOnIrq         db 'Installed!',13,10,'$'
aProgrammFromMe         db 'Removed!',13,10,'$'
aNotEnoughDOS           db 'DOS 2.0 or above required.',13,10,'$'

if modify_mcb_name
aMCBname               db 'FIXTSR',0,0
endif

main:                                
                mov     ax, cs
                mov     ds, ax


                mov     ah, 30h
                int     21h             ; DOS - GET DOS VERSION
                                        ; Return: AL = major version number (00h for DOS 1.x)
                cmp     al, 2
                jnb     short continue


                mov        ah, 9
                mov        dx, offset aNotEnoughDOS 
                int        21h ; dos print string DS:DX

                jmp l_dos_exit_norm

continue:                         
                mov        ah, 9
                mov        dx, offset aIntroMsg 
                int        21h  ; print string
                                        
                mov        ax, 3521h
                int        21h ; get int -> ES:BX 
                sub        bx, offset s_new_int_21h_113 - offset a_INSTALL_CHECK
                mov        di, bx
                mov        si, offset a_INSTALL_CHECK
                mov        cx, lengthof a_INSTALL_CHECK
                repe cmpsb
                or        cx, cx
                jnz        short l_install_vect



                mov        si, 80h ; command line args
                mov        cx, 14h
                lodsb       ;; get number of chars
                cmp        al, 0
                jz        short l_already_installed  

l_opt_search_loop:                                
                lodsb
                cmp        al, '-'
                jz        short l_check_r_option
                cmp        al, '/'
                jz        short l_check_r_option
                loop        l_opt_search_loop
                jmp        short l_already_installed


l_check_r_option:                                
                lodsb
                and        al, 0DFh ;; uppercase
                cmp        al, 'R'
                jz        short l_uninstall
                jmp        short l_already_installed


l_uninstall:                                
                mov        ah, 9
                mov        dx, offset aProgrammFromMe ; "Program from Memory Removed !!\n\r$"
                int        21h ; dos print string DS:DX

                ; clear install check
                mov        di, offset a_INSTALL_CHECK
                mov        cx, lengthof a_INSTALL_CHECK
                mov        al, 2Ah
                rep stosb


                mov     dx, word ptr es:dw_dos_21h_orig
                mov     ax, word ptr es:dw_dos_21h_orig+2
                mov        ds, ax
                mov        ax, 2521h
                int        21h  ; dos set vector DS:DX

                mov        bx, es
                mov        es, es:[2Ch]
                mov        ah, 49h
                int        21h  ; dos free  : ES seg

                mov        es, bx
                mov        ah, 49h
                int        21h  ; dos free  : ES seg

                jmp        short l_dos_exit_norm


l_already_installed:                                
                mov        dx, offset aAlreadyInstalledMsg ; "Already installed        !!\n\r(Remove with /r o"...
                mov        ah, 9
                int        21h  ; dos print string DS:DX

l_dos_exit_norm:                                
                mov        ax, 4C00h
                int        21h  ; exit with code


l_install_vect:                                
                mov        ax, 3521h
                int        21h  ; dos get vect -> ES:BX  al = int to get
                mov        word ptr dw_dos_21h_orig+2, es
                mov        word ptr dw_dos_21h_orig, bx

if modify_mcb_name
                ; change MCB to identify it!
                mov        bx, cs
                dec        bx
                mov        es, bx
                mov        di, 8
                mov        si, offset aMCBname
                mov        cx, 8
                rep movsb
endif

                mov        ax, 2521h
                mov        dx, offset s_new_int_21h_113
                int        21h   ;dos set interrupt ; DS:DX - interrupt al = int to set

                mov        ah, 9
                mov        dx, offset aInstalledOnIrq ; "Installed        on IRQ 21 !\n\r$"
                int        21h  ; dos print string DS:DX

                ; calculate paragraphs
                mov        dx, offset a_tsr_last_byte_163
                mov        cl, 4
                shr        dx, cl
                inc        dx

                mov        ax, 3100h
                int        21h ; Terminate and Stay Resident
                ; ah = 31h
                ; al = return code (0)
                ; dx = number of paragraphs to keep.



END start
