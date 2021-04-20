#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <conio.h>
#include <joystick.h>

int main (void)
{
    unsigned char j;
    unsigned char count;
    unsigned char i;
    unsigned char Res;
    unsigned char ch, kb;

    clrscr ();


    Res = joy_install (&joy_static_stddrv);



    count = joy_count ();
#if defined(__ATARI5200__) || defined(__CREATIVISION__)
    cprintf ("JOYSTICKS: %d", count);
#else
    cprintf ("Driver supports %d joystick(s)", count);
#endif
    while (1) {
        for (i = 0; i < count; ++i) {
            gotoxy (0, i+1);
            j = joy_read (i);
#if defined(__ATARI5200__) || defined(__CREATIVISION__)
            cprintf ("%1d:%-3s%-3s%-3s%-3s%-3s %02x",
                     i,
                     JOY_UP(j)?    " U " : " - ",
                     JOY_DOWN(j)?  " D " : " - ",
                     JOY_LEFT(j)?  " L " : " - ",
                     JOY_RIGHT(j)? " R " : " - ",
                     JOY_BTN_1(j)? " 1 " : " - ", j);
#else
            cprintf ("%2d: %-6s%-6s%-6s%-6s%-6s %02x",
                     i,
                     JOY_UP(j)?    "  up  " : " ---- ",
                     JOY_DOWN(j)?  " down " : " ---- ",
                     JOY_LEFT(j)?  " left " : " ---- ",
                     JOY_RIGHT(j)? "right " : " ---- ",
                     JOY_BTN_1(j)? "button" : " ---- ", j);
#endif
        }

        /* show pressed key, so we can verify keyboard is working */
        kb = kbhit ();
        ch = kb ? cgetc () : ' ';
        gotoxy (1, i+2);
        revers (kb);
        cprintf ("kbd: %c", ch);
        revers (0);
    }
    return 0;
}
