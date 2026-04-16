module btn_debouncer #(
    parameter int WAIT_TIME = 500_000 // 50MHz 클럭 기준 10ms
)(
    input  logic clk,           // 시스템 클럭
    input  logic rst,           // Active-High 비동기 리셋 (변경됨)
    input  logic button_in,     // 불안정한 외부 버튼 입력
    output logic button_pulse   // 버튼이 눌리는 순간 발생하는 1클럭 펄스 출력
);

    localparam int COUNTER_WIDTH = $clog2(WAIT_TIME);
    
    logic [COUNTER_WIDTH-1:0] counter;
    logic sync_0;
    logic sync_1; 
    logic debounced_state;   // 디바운싱 완료된 안정적인 버튼 상태
    logic debounced_state_d; // 1클럭 지연된 버튼 상태 (Edge 검출용)

    // 1. 비동기 입력 신호 2단 동기화
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= button_in;
            sync_1 <= sync_0;
        end
    end

    // 2. 디바운스 로직 (상태 안정화)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter         <= '0;
            debounced_state <= 1'b0;
        end else begin
            if (debounced_state == sync_1) begin
                counter <= '0; 
            end else begin
                counter <= counter + 1'b1;
                if (counter == WAIT_TIME - 1) begin
                    debounced_state <= sync_1; 
                    counter         <= '0;
                end
            end
        end
    end

    // 3. 엣지 디텍터 (1클럭 지연 레지스터)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            debounced_state_d <= 1'b0;
        end else begin
            // 현재의 안정된 상태를 다음 클럭에 저장
            debounced_state_d <= debounced_state;
        end
    end

    // 4. 1클럭 펄스 생성 (Rising Edge Detection)
    // 현재 상태(debounced_state)가 1이고, 이전 상태(debounced_state_d)가 0일 때만 1 출력
    assign button_pulse = debounced_state & ~debounced_state_d;

endmodule