#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <conio.h>

static unsigned char buf[10];

int main() {
    static FILE *fp;
    static int nb;
    static unsigned char key;
    static unsigned char i=0;
   


    while (1) 
    {
        if (i==0) strcpy(buf,"Hello 0");
        if (i==1) strcpy(buf,"Hello 1");
        
        printf("Press space or esc\n");
        key=cgetc();
        if (key==' ') {
            i++;
            remove("toto.txt");
            fp=fopen("/toto.txt","wb");

            if (fp==NULL) {
                printf("Error\n");
                return 0;
            }

            nb=fwrite(buf,1,10,fp);

            printf("nb=%d\n",nb);
            fclose(fp);
            
        }
        if (key==27) break;
    }




}