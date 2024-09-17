# Palace of Deceit Notes


## Files

 * PALOFDEC.EXE - orig, packed
 * PALOFDEC.EXE.unpacked - unpacked exe
 * PALFIXED.EXE - patched prototype exe
 * PALOFDEC.idb - ida pro file

## Analysis

When pulling a shield from a knight, the game crashes with the message:

    Illegal function call in module PALOFDEC at address 01A2:1470

Which is basically around here:

    ....
    seg000:1467                 mov     ax, 1BAEh
    seg000:146A                 push    ax
    seg000:146B                 call    s_CRASHING_70CC

    seg000:1470                 mov     ax, 1BC4h
    ....

And within s_CRASHING_70CC:

    ....
    seg002:0EC3                 mov     bx, [bp+arg_0]
    seg002:0EC6                 mov     w_SOMETHING_16BE4, bx
    seg002:0ECA                 call    sub_7101
    seg002:0ECD                 mov     ax, word_16F0E
    ....

And within sub_7101:

    ....
    seg002:0F1D                 push    word_16A9F
    seg002:0F21                 push    word_16AA1
    seg002:0F25                 call    near ptr s_CRASHING_2_A813
    seg002:0F28                 jb      short loc_7141
    ....


and within s_CRASHING_2_A813:

    seg002:4603 s_CRASHING_2_A813 proc far              
    seg002:4603                 call    s_get_next_toupper_A8A6  ; get command
    seg002:4606                 jz      short locret_A862
    seg002:4608                 add     al, al
    seg002:460A                 mov     cl, al
    seg002:460C                 mov     bx, word_16AA3
    seg002:4610
    seg002:4610 loc_A820:                               
    seg002:4610                 mov     al, cs:[bx]  ; search jump table
    seg002:4613                 add     al, al
    seg002:4615                 jz      short loc_A830
    seg002:4617                 cmp     cl, al
    seg002:4619                 jz      short loc_A833
    seg002:461B                 inc     bx
    seg002:461C                 inc     bx
    seg002:461D                 inc     bx
    seg002:461E                 jmp     short loc_A820
    seg002:4620 
    seg002:4620
    seg002:4620 loc_A830:                               
    seg002:4620                                         
    seg002:4620                 jmp     l_ERROR_621B
    seg002:4623 
    seg002:4623
    seg002:4623 loc_A833:                               
    ....
    seg002:464E loc_A85E:                               
    seg002:464E                 jmp     word ptr cs:[bx+1] ; jump table offset
    seg002:4652 
    seg002:4652
    seg002:4652 locret_A862:                            
    seg002:4652                 retn
    seg002:4652 s_CRASHING_2_A813 endp



So basically s_get_next_toupper_A8A6 was returning an uppercase letter from a list
of characters. It seems to be a list of instructions that controls music?

A lot of the songs look like: 'mb o0 t255 addcda addcda addcda bbbaaa ba' where it
starts with "mb" for musicbox and maybe an "o" for octave?

The problem is that some songs crash the game. They actually look slightly different:
'mb05 t255 aaaaabaoa' with a zero '0' instead of 'o' for octave. I don't know if this
is just a mistyped and untested code, but because it doesn't exist in the lookup
table that is searched in seg002:4610, it crashes by jumping to l_ERROR_621B

Anyway, the fix is to replace the "0" with an "o" and the game runs fine!


## References

 * https://en.wikipedia.org/wiki/The_Palace_of_Deceit
 * https://www.mobygames.com/game/69026/the-palace-of-deceit-the-secret-of-castle-lockemoer/
 * https://advgamer.blogspot.com/2021/04/missed-classic-palace-of-deceit-secret.html
 * https://twitter.com/doctorcdcs/status/1596600461599162374
 * https://www.youtube.com/watch?v=XyeQK65Zs7w
