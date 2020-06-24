report navtree message-id >0 .

*--------------------------------------------------------------------*
*- Tipos SAP
*--------------------------------------------------------------------*
*type-pools:

*--------------------------------------------------------------------*
*- Tabelas
*--------------------------------------------------------------------*
tables:
  scarr, sflight .

*----------------------------------------------------------------------*
*       CLASS lcl_report DEFINITION
*----------------------------------------------------------------------*
class lcl_report definition.

  public section.

    types:
      begin of ty_carrid,
        sign   type sign,
        option type option,
        low    type sflight-carrid,
        high   type sflight-carrid,
      end of ty_carrid,

      begin of ty_connid,
        sign   type sign,
        option type option,
        low    type sflight-connid,
        high   type sflight-connid,
      end of ty_connid,

      begin of ty_fldate,
        sign   type sign,
        option type option,
        low    type sflight-fldate,
        high   type sflight-fldate,
      end of ty_fldate,

      carrid_range type table of ty_carrid,
      connid_range type table of ty_connid,
      fldate_range type table of ty_fldate.


    methods display_data .

    methods get_data
      importing
        !carrid type carrid_range
        !connid type connid_range
        !fldate type fldate_range .

    class-methods initial .

  protected section .

    methods on_added_function
      for event if_salv_events_functions~added_function
                  of cl_salv_events_table
      importing e_salv_function.

    methods on_link_click
      for event if_salv_events_actions_table~link_click
                  of cl_salv_events_table
      importing row
                  column.

  private section .

    types:
      begin of ty_out,
        navtree   type char2,
        carrid    type scarr-carrid,
        carrname  type scarr-carrname,
        currcode  type scarr-currcode,
        connid    type sflight-connid,
        fldate    type sflight-fldate,
        planetype type sflight-planetype,
      end of ty_out.

    data:
      salv_table type ref to cl_salv_table,
      out        type table of ty_out,
      sflight    type table of sflight,
      scarr      type table of scarr.

    methods add_items
      importing
        !row    type i
        !carrid type sflight-carrid .

    methods change
      importing
        !row type i .

    methods del_items
      importing
        !row    type i
        !carrid type sflight-carrid .

    methods organize
      importing
        !scarr   type scarr_tab
        !sflight type sflight_tab1 .

    methods process .

    methods search
      importing
        !carrid  type carrid_range
        !connid  type connid_range
        !fldate  type fldate_range
      changing
        !scarr   type scarr_tab
        !sflight type sflight_tab1 .

endclass.                    "lcl_report DEFINITION

*----------------------------------------------------------------------*
*       CLASS lcl_report IMPLEMENTATION
*----------------------------------------------------------------------*
class lcl_report implementation.

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
            t_table      = me->out.


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

  method initial .
  endmethod .                    "initial

  method on_added_function .

    me->process( ) .

  endmethod .                    "on_added_function

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

  method add_items .

    data:
      index    type syindex,
      line     type sflight,
      out_line type me->ty_out,
      new_line type ref to data.

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

  endmethod .

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

  method del_items .

    data:
      index type syindex,
      line  type sflight.

    field-symbols:
      <line> type me->ty_out .

    read table me->out assigning <line> index row .

    if sy-subrc eq 0 .

      <line>-navtree = '4' .

      delete me->out where navtree eq '3'
                       and carrid  eq carrid .

    endif .

  endmethod .

  method organize .

    data:
      scarr_line type scarr,
      out_line   type me->ty_out.

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

  method process .

    case sy-ucomm .

      when 'REFRESH' .

        if me->salv_table is bound .

          me->salv_table->refresh( ) .

        endif .

      when others .

    endcase .

  endmethod .                    "process

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

endclass.                    "lcl_report IMPLEMENTATION


*--------------------------------------------------------------------*
*- Tela de seleção
*--------------------------------------------------------------------*
data:
  objeto type ref to lcl_report.

*--------------------------------------------------------------------*
*- Tela de seleção
*--------------------------------------------------------------------*
selection-screen begin of block b1 with frame title text-001.

select-options:
  carrid for sflight-carrid,
  connid for sflight-connid,
  fldate for sflight-fldate .
selection-screen end of block b1.

*--------------------------------------------------------------------*
*- Eventos
*--------------------------------------------------------------------*
initialization.

  lcl_report=>initial( ) .


start-of-selection .

  create object objeto .

  objeto->get_data(
    exporting
      carrid = carrid[]
      connid = connid[]
      fldate = fldate[]
  ).


end-of-selection.

  objeto->display_data( ) .
