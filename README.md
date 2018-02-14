# Expansão de itens (editando) #

[![N|Solid](https://wiki.scn.sap.com/wiki/download/attachments/1710/ABAP%20Development.png?version=1&modificationDate=1446673897000&api=v2)](https://www.sap.com/brazil/developer.html)
Não encontrei um nome mais simples para ser título do projeto, logo, eu informei como ST12 ~porque o projeto é meu e eu coloco o nome mais facil de ser encontrado por mim depois~ por ser um ALV semelhante ao exibido pela transação ST12. Desconsiderar algum problema de indentação. Eu tenho um serio problema de limitação do `case`. Como ABAP não é uma linguagem `case sensitive`, ~~é muita perca de tempo querer colocar tamanho de fonte em `upper case`~~ eu não vejo necessidade de alterar o `case` sendo que o editor ja separa com cores diferentes as palavras reservadas. Mas ~~o desenvolvedor não consegue ver as cores diferentes e ainda quer colocacr em casa diferente~~ os outros ABAPer's que compartilham o mesmo usuário pensam diferente de mim, então eu faço sem `Pretty Printer`.

Neste exemplo eu tenho uma mostra de como seria se dentro de um relatório eu pudesse expandir os Itens (ou qualquer outra informação que seja) de forma que fique como um _subtotal ao contrario_. Como padrão na maioria dos meus desenvolvimentos, foi usado a classe `CL_GUI_ALV_GRID`. Alguns dados de Companhias Aereas serão exibidos e apos expandir serão mostrados os vôos referente a cia area. As aplicações são ilimitadas, basta **saber adequar seu cenário com a tecnologia que melhor atende**.

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
Uma tela de seleção com as principais chaves é exibida.
![N|Solid](https://uploaddeimagens.com.br/images/001/289/531/original/tela-de-selecao.png)

Apos, é exibido o relatório com um `hotspot` que simboliza uma `navegação tree`, conforme imagem.
![N|Solid](https://uploaddeimagens.com.br/images/001/289/535/original/click-01.png?1518610599)

A lista é expandida ao clicar no icone da pasta, fazendo com que mais detalhes sejam exibidos, e no caso, voos da cia area referente.
![N|Solid](https://uploaddeimagens.com.br/images/001/289/537/original/click-02.png?1518610742)

Essa funcionalidade é explica nos metodos abaixo.

### public section ###

#### display_data ####
Tendo o objetivo de exibir as informações, fazer considerações finais referente a exibição, como ordenação, hotspot e outros. Normalmente eu faço a chamada de subrotinas internas em métodos privados, mas no caso, preferi mater tudo dentro desse mesmo metodo.
```abap
  method display_data .

    data:
      events  type ref to cl_salv_events_table,
      display type ref to cl_salv_display_settings,
      sorts   type ref to cl_salv_sorts,
      column  type ref to cl_salv_column_list,
      columns type ref to cl_salv_columns_table.

    check lines( me->out ) gt 0 .


    try.
        call method cl_salv_table=>factory
          importing
            r_salv_table = me->salv_table
          changing
            t_table      = me->out .


        events = me->salv_table->get_event( ).

        set handler me->on_link_click for events.
        set handler me->on_added_function for events.

        me->salv_table->set_screen_status(
          pfstatus      = 'STANDARD_FULLSCREEN'
          report        = 'SAPLKKBL'
          set_functions = me->salv_table->c_functions_all ).


        columns = me->salv_table->get_columns( ).

        columns->set_optimize( 'X' ).
        column ?= columns->get_column( 'NAVTREE' ).
        column->set_icon( if_salv_c_bool_sap=>true ).
        column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        column->set_long_text( 'Nível' ).
        column->set_symbol( if_salv_c_bool_sap=>true ).

*       Layout de Zebra
        display = me->salv_table->get_display_settings( ) .
        display->set_striped_pattern( cl_salv_display_settings=>true ) .

*       Ordenação de campos
        sorts = me->salv_table->get_sorts( ) .
        sorts->add_sort('CARRID') .

        me->salv_table->display( ).

      catch cx_salv_msg .
      catch cx_salv_not_found .
      catch cx_salv_existing .
      catch cx_salv_data_error .
      catch cx_salv_object_not_found .

    endtry.

  endmethod .                    "generate_output
```
#### get_data ####
Como uma arquitetura padrão que uso para recuperação de informações, esse método por sua vez faz chamada de outros dois que são responsáveis de buscar e organizar as informações.
```abap
  method get_data.

    me->search(
      exporting
        carrid  = carrid
        connid  = connid
        fldate  = fldate
      changing
        scarr   = scarr
        sflight = sflight
    ).

    me->organize(
      exporting
        scarr   = scarr
        sflight = sflight
    ).

  endmethod.                    "GET_DATA
```
#### initial ####
Em outros report's eu uso este para habilitar/desabilitar e preencher campos da tela de seleção. Preferi manter para que eu posso fazer melhorias em versões posteriores.
```abap
  method initial .
  endmethod .                    "initial
```
