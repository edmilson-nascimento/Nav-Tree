# Expansão de itens (editando) #

[![N|Solid](https://wiki.scn.sap.com/wiki/download/attachments/1710/ABAP%20Development.png?version=1&modificationDate=1446673897000&api=v2)](https://www.sap.com/brazil/developer.html)
Não encontrei um nome mais simples para ser titulo do projeto, logo, eu informei como ST12 ~porque o projeto é meu e eu coloco o nome mais facil de ser encontrado por mim depois~ por ser um ALV semelhante ao exibido pela transação ST12. Desconsiderar algum problema de indentação. Eu tenho um serio problema, de limitação do `case`. Como o ABAP não é uma linguagem `case sensitive`, ~~é muita perca de tempo querer colocar tamanho de fonte em `upper case`~~ eu não vejo necessidade de alterar o `case` sendo que o editor ja separa com cores diferentes as palavras reservadas. Mas ~~o desenvolvedor que não consegue ver as cores diferentes e ainda quer colocacr em casa diferente~~ os outros ABAPer's que compartilham o mesmo usuário pensam diferente de mim, então eu faço sem `Pretty Printer`.

Neste eu tenho uma mostra de como seria se dentro de um relatório eu pudesse expandir os Itens (ou qualquer outra informação que seja) de forma que fique como um _subtotal ao contrario_. Como padrão na maioria dos meus desenvolvimentos, foi usado a classe `CL_GUI_ALV_GRID`. Alguns dados de vôos serão exibidos e apos expandir serão mostrados os vôos referente a cia area. As aplicações são ilimitadas, basta *saber adequar seu cenário com a tecnologia que melhor atende*.

Alguns métodos estão sem desenvolvimento, mas eu preferi manter para possíveis melhorias. Enquanto eu estiver com acesso ao SAP nessa versão, vou continuar trabalhando com classes locais e no caso dessa é a `LCL_REPORT` com os seguintes métodos:

* public section
	* [display_data](#display_data)
	* [get_data](#get_data)
	* [initial](#initial)  

* protected section
	* [on_added_function](#on_added_function)
	* [on_link_click](#on_link_click)

* private section
	* [add_items](#add_items)
	* [change](#change)
	* [del_items](#del_items)  
	* [organize](#add_items)
	* [process](#change)
	* [search](#del_items)  
	
## Informações Exibidas ##


### public section ###

#### display_data ####
.
```abap
.
```
#### get_data ####
.
```abap
.
```
#### initial ####
.
```abap
.
```
