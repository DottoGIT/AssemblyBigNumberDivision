global sdiv
section .text
sdiv:
    push    ebp         ; Prolog
    mov ebp, esp
    push    ebx
    push    esi
    push    edi
    mov esi, [ebp + 12] ; adres ilorazu (d)
    mov edi, [ebp + 16] ; adres s1
    xor ecx, ecx        ; iterator po ilorazie (d)
    mov edx, '0'        ; licznik ilorazu
main_loop:
                        ; PORÓWNYWANIE NAPISÓW
    push edi            ; adres pierwszej liczby
    push esi            ; adres drugiej liczby
    push edx            ; dh, dl - znaki napisow
    push ecx            ; jaki fragment napisu porownujemy
    xor ebx, ebx        ; iterator po napisie
    mov edi, [ebp+16] 
    mov esi, [ebp+20] 
subtractStrings_skipS1Zeros: ; Omiń zera wiodące w s1
    cmp [edi + ebx], byte '0'
    jne compareStrings_CheckLength
    inc edi
    dec ecx
    jge subtractStrings_skipS1Zeros
    pop ecx             ; Zakończ funkcje z wynikiem s1 < s2
    pop edx
    pop esi
    pop edi
    jmp main_loop_s1_smaller
compareStrings_CheckLength: ; Porównaj długości
    cmp [edi + ebx], byte 0
    je compareStrings_CheckLength_ResultS1Ended
    cmp [esi + ebx], byte 0
    jne compareStrings_CheckLength_continue0
    pop ecx             ; Zakończ funkcje z wynikiem s1 >= s2
    pop edx
    pop esi
    pop edi
    jmp main_loop_s1_not_smaller
compareStrings_CheckLength_continue0:
    inc ebx
    cmp ebx, ecx
    jle compareStrings_CheckLength
compareStrings_CheckLength_ResultS1Ended:
    cmp [esi + ebx], byte 0
    je compareStrings_CheckLength_SameSize

    pop ecx             ; Zakończ funkcje z wynikiem s1 < s2
    pop edx
    pop esi
    pop edi
    jmp main_loop_s1_smaller
compareStrings_CheckLength_SameSize:
    xor ebx, ebx
compreString_CompareLetters: ; Jeżeli znaki są równe porównaj poszczególne litery
    mov dh, [edi + ebx]
    mov dl, [esi + ebx]
    test dh, dh
    jnz compreString_CompareLetters_Continue0
    pop ecx             ; Zakończ funkcje z wynikiem s1 >= s2
    pop edx
    pop esi
    pop edi
    jmp main_loop_s1_not_smaller

compreString_CompareLetters_Continue0:
    cmp dh, dl
    je compreString_CompareLetters_SameLetters
    pop ecx             ; Zakończ funkcje
    pop edx
    pop esi
    pop edi
    jg main_loop_s1_not_smaller
    jmp main_loop_s1_smaller
compreString_CompareLetters_SameLetters:
    inc ebx             ; Sprawdź kolejną literę
    cmp ebx, ecx
    jle compreString_CompareLetters
    pop ecx             ; Zakończ funkcje z wynikiem s1 >= s2
    pop edx
    pop esi
    pop edi
    jmp main_loop_s1_not_smaller
    ; KONIEC PORÓWNANIA
main_loop_s1_smaller:   
    cmp edx, '9'        ; Jeżeli edx jest większe od '9' dodaj do niego 7 (przez lukę w ASCII między cyframi, a literami)
    jbe main_loop_dont_add_7
    add edx, 7
main_loop_dont_add_7:
    mov [esi + ecx], edx
    mov edx, '0'
    inc ecx
    cmp [edi + ecx], byte 0
    jne main_loop
finish:
    mov ecx, esi
    call crop_zeros_from_string
    mov ecx, edi
    call crop_zeros_from_string
    mov eax, [ebp + 12]
    pop edi
    pop esi
    pop ebx
    pop ebp
    ret
main_loop_s1_not_smaller:
                    ; ODEJMIJ NAPISY
    push ebx        ; iterator po s2
    push esi        ; adres drugiej liczby
    push edx        ; dh, dl - litery wyrazow
    push ecx        ; pragment napisu do odjecia
    xor eax, eax    ; ah - flaga pożyczki      1 | pożyczono       0 | nie pożyczono
    mov esi, [ebp+20]
    xor ebx, ebx
    xor ah, ah
subtractStrings_FindEndPom2: ; Przejdź na koniec s2
    mov dl, [esi + ebx]
    inc ebx
    test dl, dl
    jg subtractStrings_FindEndPom2
    sub ebx, 2
subtractStrings_Loop:  ; Rozpocznij odejmowanie
    mov dh, [edi + ecx]
    mov dl, '0'
    test ebx, ebx
    jl subtractStrings_Loop_skipDl
    mov dl, [esi + ebx]
subtractStrings_Loop_skipDl:
    cmp dh, '9' ; jeżeli dh lub dl > 9 odejmij od nich 7, bo w ASCII litery są oddalone o 7 od cyfr
    jbe subtractStrings_Loop_dhNotLetter
    sub dh, 7
subtractStrings_Loop_dhNotLetter:
    cmp dl, '9'
    jbe subtractStrings_Loop_dlNotLetter
    sub dl, 7
subtractStrings_Loop_dlNotLetter:
    sub dh, dl
    sub dh, ah
    add dh, '0'
    xor ah, ah
subtractStrings_Loop_StopDhCheck:
    cmp dh, '0'
    jge subtractStrings_Loop_StopNegativeCheck
    add dh, byte [ebp + 8]
    mov ah, 1
subtractStrings_Loop_StopNegativeCheck:
    cmp dh, '9'
    jbe subtractStrings_Loop_ResultLetter
    add dh, 7
subtractStrings_Loop_ResultLetter:
    mov [edi + ecx], dh
    sub ebx, 1
    sub ecx, 1
    jge subtractStrings_Loop
    pop ecx ; Epilog odejmowania
    pop edx
    pop esi
    pop ebx

    inc edx ; Po odjęciu zaktualiuj edx main_loop (dzielnik ponownie zmieścił się w fragmencie dzielnej
    jmp main_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; CROP ZEROS FUNCTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
crop_zeros_from_string:
    ; pobierane ecx: adres słowa z którego usunięte zostaną zera wiodące
    ; eax - liczba zer wiodących
    ; ebx - iterator
    ; dh - pomocnicza
    xor eax, eax
    xor ebx, ebx
crop_zeros_from_results_countBufferZeros:
    cmp [ecx + eax], byte "0"
    jg crop_zeros_from_results_countBufferZeros_Finish
    cmp [ecx + eax], byte 0
    je crop_zeros_from_results_BufferIsZero
    inc eax
    jmp crop_zeros_from_results_countBufferZeros
crop_zeros_from_results_countBufferZeros_Finish:
    test eax, eax
    jg crop_zeros_from_results_replaceLoopBuffer
    ret
crop_zeros_from_results_replaceLoopBuffer:
    mov dh, [ecx + eax]
    mov [ecx + ebx], dh
    mov [ecx + eax], byte 0
    inc ebx
    inc eax
    cmp [ecx + eax], byte 0
    jne crop_zeros_from_results_replaceLoopBuffer
    mov [ecx + ebx], byte 0
    ret
crop_zeros_from_results_BufferIsZero:
    mov [ecx + 1], byte 0
    ret