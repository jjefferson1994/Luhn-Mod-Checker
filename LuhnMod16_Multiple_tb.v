module luhnMod16_multiple_tb;

  reg clock, rst_n;

  // size interface
  reg [7:0] size;
  reg size_valid;
  wire size_ready;

  // message data interface
  reg [3:0] data;
  reg data_valid;
  wire data_ready;

  // check interface
  wire check;
  wire check_valid;
  reg check_ready;
  reg reg_check;
  reg result;

  // simulation variables
  reg [3:0] data_vec_000 [0:7];
  reg [3:0] data_vec_001 [0:11];
  reg [3:0] data_vec_002 [0:30];
  reg [3:0] data_vec_003 [0:4];
  reg [3:0] data_vec_004 [0:7];
  reg [3:0] data_vec_005 [0:15];
  integer data_rnd;
  integer zero_more_rnd_delay;
  integer i, j, i_max;
  integer error_cnt;

  always #5 clock = ~clock;

  initial
  begin
    clock       = 0;
    rst_n       = 0;
    size        = 8'h8;
    size_valid  = 0;
    data        = 4'h0;
    data_valid  = 0;
    check_ready = 0;
    error_cnt   = 0;

    // example from the writeup
    data_vec_000[0] = 4'hA;
    data_vec_000[1] = 4'h3;
    data_vec_000[2] = 4'hD;
    data_vec_000[3] = 4'hC;
    data_vec_000[4] = 4'h1;
    data_vec_000[5] = 4'h5;
    data_vec_000[6] = 4'h9;
    data_vec_000[7] = 4'h7;

    data_vec_001[ 0] = 4'hD;
    data_vec_001[ 1] = 4'hE;
    data_vec_001[ 2] = 4'hA;
    data_vec_001[ 3] = 4'hD;
    data_vec_001[ 4] = 4'hB;
    data_vec_001[ 5] = 4'hE;
    data_vec_001[ 6] = 4'hE;
    data_vec_001[ 7] = 4'hF;
    data_vec_001[ 8] = 4'hC;
    data_vec_001[ 9] = 4'hC;
    data_vec_001[10] = 4'h9;
    data_vec_001[11] = 4'hC;

    data_vec_002[ 0] = 4'hF;
    data_vec_002[ 1] = 4'hC;
    data_vec_002[ 2] = 4'hB;
    data_vec_002[ 3] = 4'h5;
    data_vec_002[ 4] = 4'h6;
    data_vec_002[ 5] = 4'hE;
    data_vec_002[ 6] = 4'h3;
    data_vec_002[ 7] = 4'h5;
    data_vec_002[ 8] = 4'hC;
    data_vec_002[ 9] = 4'h4;
    data_vec_002[10] = 4'hD;
    data_vec_002[11] = 4'hC;
    data_vec_002[12] = 4'hE;
    data_vec_002[13] = 4'hE;
    data_vec_002[14] = 4'h9;
    data_vec_002[15] = 4'h8;
    data_vec_002[16] = 4'hE;
    data_vec_002[17] = 4'h6;
    data_vec_002[18] = 4'hC;
    data_vec_002[19] = 4'h5;
    data_vec_002[20] = 4'hB;
    data_vec_002[21] = 4'h3;
    data_vec_002[22] = 4'h8;
    data_vec_002[23] = 4'h8;
    data_vec_002[24] = 4'hB;
    data_vec_002[25] = 4'hE;
    data_vec_002[26] = 4'h5;
    data_vec_002[27] = 4'h6;
    data_vec_002[28] = 4'h5;
    data_vec_002[29] = 4'hC;
    data_vec_002[30] = 4'hD;

    data_vec_003[0] = 4'h4;
    data_vec_003[1] = 4'hC;
    data_vec_003[2] = 4'hA;
    data_vec_003[3] = 4'h5;
    data_vec_003[4] = 4'hF;

    data_vec_004[0] = 4'h6;
    data_vec_004[1] = 4'h9;
    data_vec_004[2] = 4'h4;
    data_vec_004[3] = 4'h3;
    data_vec_004[4] = 4'h2;
    data_vec_004[5] = 4'h1;
    data_vec_004[6] = 4'hA;
    data_vec_004[7] = 4'hB;

    data_vec_005[ 0] = 4'hF;
    data_vec_005[ 1] = 4'hC;
    data_vec_005[ 2] = 4'hB;
    data_vec_005[ 3] = 4'hA;
    data_vec_005[ 4] = 4'h8;
    data_vec_005[ 5] = 4'hE;
    data_vec_005[ 6] = 4'h3;
    data_vec_005[ 7] = 4'h5;
    data_vec_005[ 8] = 4'hC;
    data_vec_005[ 9] = 4'h4;
    data_vec_005[10] = 4'hD;
    data_vec_005[11] = 4'hC;
    data_vec_005[12] = 4'hE;
    data_vec_005[13] = 4'hE;
    data_vec_005[14] = 4'h9;
    data_vec_005[15] = 4'h8;

    #20
    rst_n       = 1;

    for( j=0; j<6; j=j+1 ) begin

      case( j )
        0: i_max = 8;
        1: i_max = 12;
        2: i_max = 31;
        3: i_max = 5;
        4: i_max = 8;
        5: i_max = 16;
        default: i_max = 0;
      endcase

      size = i_max;

      // reset has setup the whole system
      // send a size
      #10

      // ensure that size_ready is low first
      wait( size_ready == 0 );
      // once seen low then wait until clock edge ...
      @( posedge clock );
      // ... and then for 5 more units to assert
      // size_valid
      #5
      size_valid = 1;
      // wait until size_ready becomes high across
      // another rising clock edge ...
      wait( size_ready == 1 );
      @( posedge clock );
      #5
      // ... and size_valid goes low again
      size_valid = 0;
      @( posedge clock );

      // now we wait a random number of cycles
      // before we send data.  And, we wait a
      // random number of cycles between sending
      // each nibble

      for( i=0; i<i_max; i=i+1 ) begin
        zero_more_rnd_delay = {$random} % 2;
        data_rnd = {$random} % 8 + 1;
        if( zero_more_rnd_delay != 0 ) begin
          #5 data_valid = 0;
          repeat( data_rnd ) @( posedge clock );
        end

          case( j )
            0: data = data_vec_000[i];
            1: data = data_vec_001[i];
            2: data = data_vec_002[i];
            3: data = data_vec_003[i];
            4: data = data_vec_004[i];
            5: data = data_vec_005[i];
            default: data = 0;
          endcase

        #5 data_valid = 1;
        wait( data_ready == 1 );
        @( posedge clock );
      end
      #5
      data_valid = 0;

      // all the data have been sent so we wait for
      // the check value to appear
      wait( check_valid );
      @( posedge clock );
      #5
      check_ready = 1;
      reg_check   = check;
      @( posedge clock );
      #5
      check_ready = 0;
      @( posedge clock );

      // display some text related to the value of the
      // check bit that came out
      case( j )
        0: result = 1;
        1: result = 1;
        2: result = 0;
        3: result = 1;
        4: result = 0;
        5: result = 1;
        default: result = 0;
      endcase

      #10
      if( reg_check == result ) begin
        $display( "check values match for scenario %d", j );
      end
      else begin
        $display( "check values DON'T match for scenario %d", j );
        error_cnt = error_cnt + 1;
      end

      #20
      @( posedge clock );
    end

    #20

    if( error_cnt > 0 ) begin
      $display( "calculation failed on %d scenarios", error_cnt );
    end
    else begin
      $display( "Seems good for these cases" );
    end

    #10
    $stop;
  end

  luhnmod16 DUT(
    .clock( clock ),
    .rst_n( rst_n ),
    .size_valid( size_valid ),
    .size_ready( size_ready ),
    .size( size ),
    .data_valid( data_valid ),
    .data_ready( data_ready ),
    .data( data ),
    .check_valid( check_valid ),
    .check_ready( check_ready ),
    .check( check )
  );

endmodule
