#include "kernel.h"
#include <stddef.h>
#include <stdint.h>

//memory location of where to write the ascii characters
uint16_t* video_mem = 0;
uint16_t terminal_row = 0;
uint16_t terminal_col = 0;

uint16_t terminal_make_char(char c, char color)
{
    //equivalent to video_mem[0] = 0x{color_byte}{character ascii byte}
    return (color << 8) | c;
}

void terminal_putchar(int row, int col, char c, char color)
{
    video_mem[row*VGA_WIDTH + col] = terminal_make_char(c,color);
}

void terminal_writechar(char c, char color)
{
    if(c == '\n')
    {
        terminal_row += 1;
        terminal_col = 0;
        return;
    }
    terminal_putchar(terminal_row,terminal_col,c,color);
    terminal_col +=1;
    if(terminal_col >= VGA_WIDTH)
    {
        terminal_col = 0;
        terminal_row += 1;
    }
}

//remove all the BIOS clutter and prepare a clean slate for the terminal
void terminal_initialize()
{
    video_mem = (uint16_t*)(0xB8000);
    terminal_col = 0;
    terminal_row = 0;
    for(int row=0;row<VGA_HEIGHT;++row)
    {
        for(int col=0;col<VGA_WIDTH;++col)
        {
            terminal_putchar(row,col,' ',0);
        }
    }
}

size_t strlen(const char* str)
{
    size_t len = 0;
    while(str[len])
    {
        len++;
    }

    return len;
}

void print(const char* str)
{
    size_t len = strlen(str);
    for(int i = 0;i<len;++i)
    {
        terminal_writechar(str[i],15);
    }

}

void kernel_main()
{
    // video_mem[0] = terminal_make_char('A',4);
    terminal_initialize();
    print("hello world \nfrom kernel!");
}