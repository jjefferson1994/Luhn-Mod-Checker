module luhnMod16_Fail_tb;

  localparam NUM_DATA_ELEMENTS = 31;

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

  // simulation variables
  reg [3:0] data_vec [0:NUM_DATA_ELEMENTS-1];
  integer data_rnd;
  integer zero_more_rnd_delay;
  integer i;

  always #5 clock = ~clock;

  initial
  begin
    clock       = 0;
    rst_n       = 0;
    size        = NUM_DATA_ELEMENTS;
    size_valid  = 0;
    data        = 4'h0;
    data_valid  = 0;
    check_ready = 0;

    // large example, odd number of nibbles, that fails
    data_vec[ 0] = 4'hF;
    data_vec[ 1] = 4'hC;
    data_vec[ 2] = 4'hB;
    data_vec[ 3] = 4'h5;
    data_vec[ 4] = 4'h6;
    data_vec[ 5] = 4'hE;
    data_vec[ 6] = 4'h3;
    data_vec[ 7] = 4'h5;
    data_vec[ 8] = 4'hC;
    data_vec[ 9] = 4'h4;
    data_vec[10] = 4'hD;
    data_vec[11] = 4'hC;
    data_vec[12] = 4'hE;
    data_vec[13] = 4'hE;
    data_vec[14] = 4'h9;
    data_vec[15] = 4'h8;
    data_vec[16] = 4'hE;
    data_vec[17] = 4'h6;
    data_vec[18] = 4'hC;
    data_vec[19] = 4'h5;
    data_vec[20] = 4'hB;
    data_vec[21] = 4'h3;
    data_vec[22] = 4'h8;
    data_vec[23] = 4'h8;
    data_vec[24] = 4'hB;
    data_vec[25] = 4'hE;
    data_vec[26] = 4'h5;
    data_vec[27] = 4'h6;
    data_vec[28] = 4'h5;
    data_vec[29] = 4'hC;
    data_vec[30] = 4'hD;

    #20
    rst_n       = 1;

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
    for( i=0; i<NUM_DATA_ELEMENTS; i=i+1 ) begin
      zero_more_rnd_delay = {$random} % 2;
      data_rnd = {$random} % 8;
      if( zero_more_rnd_delay != 0 ) begin
        #5 data_valid = 0;
        repeat( data_rnd ) @( posedge clock );
      end
      #5 data_valid = 1; data = data_vec[i];
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
    @( posedge clock );
    #5
    check_ready = 0;
    @( posedge clock );

    #10
    if( !reg_check )
      $display( "Seems good for this case" );
    else
      $display( "Something is amiss" );

    #20
    $stop;
  end

  // register that latches the check output from the
  // module on a check_valid/check_ready ready cycle
  // to be able to be used for comparison later
  always@( posedge clock )
    if( !rst_n )
      reg_check <= 0;
    else
      if( check_ready && check_valid )
        reg_check <= check;
      else
        reg_check <= reg_check;

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
