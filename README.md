# Expansão de itens (nav tree) #
 
![Static Badge](https://img.shields.io/badge/development-abap-blue)
![GitHub commit activity (branch)](https://img.shields.io/github/commit-activity/t/edmilson-nascimento/Nav-Tree)
![Static Badge](https://img.shields.io/badge/murilo-abap-green)


> 🗘 Este documento, assim como o negócio, está em constante fase de melhoria e adaptação.

Não encontrei um nome mais simples para ser título do projeto, logo, eu informei como ST12 ~porque o projeto é meu e eu coloco o nome mais facil de ser encontrado por mim depois~ por ser um ALV semelhante ao exibido pela transação ST12. Desconsiderar algum problema de indentação. Eu tenho um sério problema de limitação do `case`. Como ABAP não é uma linguagem `case sensitive`, ~~é muita perca de tempo querer colocar tamanho de fonte em `upper case`~~ eu não vejo necessidade de alterar o `case` sendo que o editor já separa com cores diferentes as palavras reservadas. Mas ~~o desenvolvedor não consegue ver as cores diferentes e ainda quer colocacr em casa diferente~~ os outros ABAPer's que compartilham o mesmo usuário pensam diferente de mim, então eu faço sem `Pretty Printer`.

Neste exemplo eu tenho uma mostra de como seria se dentro de um relatório eu pudesse expandir os Itens (ou qualquer outra informação que seja) de forma que fique como um _subtotal ao contrário_. Como padrão na maioria dos meus desenvolvimentos, foi usado a classe `CL_GUI_ALV_GRID`. Alguns dados de Companhias Aéreas serão exibidos e após expandir serão mostrados os vôos referente a cia aérea. As aplicações são ilimitadas, basta **saber adequar seu cenário com a tecnologia que melhor atende**.

## Informações Exibidas ##
Uma tela de seleção com as principais chaves é exibida.

![N|Solid](https://uploaddeimagens.com.br/images/001/289/531/original/tela-de-selecao.png)

Após, é exibido o relatório com um `hotspot` que simboliza uma `navegação tree`, conforme imagem.

![N|Solid](https://uploaddeimagens.com.br/images/001/289/535/original/click-01.png?1518610599)

A lista é expandida ao clicar no ícone da pasta, fazendo com que mais detalhes sejam exibidos, e no caso, voos da cia aérea referente.

![N|Solid](https://uploaddeimagens.com.br/images/001/289/537/original/click-02.png?1518610742)

Essa funcionalidade é explica nos metodos abaixo.

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
	* [process](#process)
	* [search](#del_items)  

### public section ###

#### display_data ####
Tendo o objetivo de exibir as informações, fazer considerações finais referente a exibição, como ordenação, hotspot e outros. Normalmente eu faço a chamada de sub-rotinas internas em métodos privados, mas no caso, preferi manter tudo dentro desse mesmo metodo.
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

### protected section ###

#### on_added_function ####
Neste temos a chamada do outro método, process, que será referente a ações requisitas após a geração do relatório.
```abap
  method on_added_function .

    me->process( ) .

  endmethod .                    "on_added_function
```

#### on_link_click ####
A ação do hotspot, será contemplada nesse método, de forma a controlar de acordo com a coluna onde foi iniciada a ação.
```abap
  method on_link_click .

    data:
      columns type ref to cl_salv_columns_table .

    case column .

      when 'NAVTREE' .

        me->change(
          exporting
            row = row
        ).

        columns = me->salv_table->get_columns( ).
        columns->set_optimize( if_salv_c_bool_sap=>true ).
        me->salv_table->refresh( ) .

      when others .

    endcase .

  endmethod .
```
### private section ###

#### add_items ####
Ao clicar no `hotspot`, novos itens são adicionados, o que passa ao usuário a impressão de um nova lista expandida. Isso é feito através do método abaixo.
```abap
  method add_items .

    data:
      index    type syindex,
      line     type sflight,
      out_line type me->ty_out,
      new_line type ref to data .

    field-symbols:
      <line> type me->ty_out .

    read table me->out assigning <line> index row .
    if sy-subrc eq 0 .
      <line>-navtree = '5' .
      unassign <line> .
    endif .

    index = row .

    create data new_line like line of me->out .
    assign new_line->* to <line> .

    loop at me->sflight into line
                  where carrid eq carrid .

      index = index + 1 .

      <line>-navtree   = '3' .
      <line>-carrid    = line-carrid .

      read table me->out into out_line
        with key carrid = carrid .
      if sy-subrc eq 0 .
        <line>-carrname  = out_line-carrname .
        <line>-currcode  = out_line-currcode .
      endif .

      <line>-connid    = line-connid .
      <line>-fldate    = line-fldate .
      <line>-planetype = line-planetype .

      insert <line> into me->out index index .

    endloop .

  endmethod.
```

#### change ####
Esse método, detém a chamada de outros dois métodos, de acordo com o ícone que foi clicado, pode ser para expandir ou recolher uma lista. Isso é definido na rotina abaixo.
```abap
  method change .

    field-symbols:
      <line> type me->ty_out .

    read table me->out assigning <line> index row .
    if sy-subrc eq 0 .

      case <line>-navtree .
        when '4' . "Pasta fechada

          me->add_items(
            exporting
              row    = row
              carrid = <line>-carrid
          ).

        when '5' . "Pasta aberta

          me->del_items(
            exporting
              row  = row
              carrid = <line>-carrid
          ).

      endcase .

    endif .

  endmethod .
```

#### del_items ####
Ao clicar no ícone, quando ja foi expandido, o usuário pode também recolher essa lista, e isso é contemplado na rotina a seguir.
```abap
  method del_items .

    data:
      index type syindex,
      line  type sflight .

    field-symbols:
      <line> type me->ty_out .

    read table me->out assigning <line> index row .

    if sy-subrc eq 0 .

      <line>-navtree = '4' .

      delete me->out where navtree eq '3'
                       and carrid  eq carrid .

    endif .

  endmethod .

```

#### organize ####
A mostra de informações é feita em dois passos: recuperação de dados e organização desses dados para que se tornem informações. Essa segunda parte é contemplada neste método.
```abap
  method organize .

    data:
      scarr_line type scarr,
      out_line   type me->ty_out .

    refresh:
      me->out .

    loop at scarr into scarr_line .

      out_line-navtree  = '4' .
      out_line-carrid   = scarr_line-carrid .
      out_line-carrname = scarr_line-carrname .
      out_line-currcode = scarr_line-currcode .

      append out_line to me->out .
      clear  out_line .

    endloop .

  endmethod .
```

#### process ####
Este método contempla ações que são executadas apos a geração do relatório, como um `refresh` por exemplo. Para essa solução, **ainda** não foi implementada nenhuma ação, apenas uma atualização mas não esta sendo chamada.
```abap
  method process .

    case sy-ucomm .

      when 'REFRESH' .

        if me->salv_table is bound .

          me->salv_table->refresh( ) .

        endif .

      when others .

    endcase .

  endmethod .                    "process
```

#### search ####
Este é responsável pelo acesso as tabelas e busca das informações no banco de dados, de forma e recuperar esses dados de acordo com os filtros da tela de seleção.
```abap
  method search .

    data:
      filter type bvw_tab_where .

    refresh:
      scarr, sflight .

    if lines( carrid ) eq 0 .
    else .
      append 'carrid in carrid' to filter .
    endif .


    if lines( filter ) eq 0 .

      select *
        into table scarr
        from scarr .
    else .

      select *
        into table scarr
        from scarr
       where (filter) .
     endif .

    if sy-subrc eq 0 .

      refresh:
        filter .

      append 'carrid eq scarr-carrid' to filter .

      if lines( connid ) eq 0 .
      else .
        append 'and connid in connid' to filter .
      endif .


      if lines( fldate ) eq 0 .
      else .
        append 'and fldate in fldate' to filter .
      endif .

      select *
        into table sflight
        from sflight
         for all entries in scarr
       where (filter) .

    endif .

    free:
      filter .

  endmethod.
```
