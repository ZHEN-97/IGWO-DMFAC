
function [sys,x0,str,ts]=modelfree(t,x,u,flag,c,d,f)%c是ρ d是μf是fai
switch flag
case 0 %Initialization
 [sys,x0,str,ts]=mdlInitializeSizes;
case 2 %Update
 sys=mdlUpdates(x,u,f,d);
case 3 %Outputs
 sys=mdlOutputs(t,x,u,c,d,f);
case {1,4,9} %Terminate
 sys=[];
otherwise 
 error(['Unhandled flag=',num2str(falg)]);
end
%Function:mdlInitializeSizes.
%S-function running with period of 1 second
%Number of inputs is 3(discstates).
%The number of output is 1.
%Passed in to the S-function.
function [sys,x0,str,ts]=mdlInitializeSizes
sizes=simsizes;
sizes.NumContStates=0; %设置系统连续状态的数量
sizes.NumDiscStates=3;%设置系统离散状态的数量
sizes.NumOutputs=1; %设置系统输出的数量
sizes.NumInputs=3;%设置系统输入的数量
sizes.DirFeedthrough=1;%设置系统直接通过量的数量，一般为1
sizes.NumSampleTimes=1;% at least one sample time is needed
                            % 需要的样本时间，一般为1.
                            % 猜测为如果为n，则下一时刻的状态需要知道前n个状态的系统状态
sys=simsizes(sizes);
x0=[0,0,0];
str=[];
ts=[0.1 0];
%Function:mdlUpdates
%Each state by the amount specified in the vararg inputs.
%Where x(1)=u(1)=e(1),x(2)=u(2)=f,x(3)=u(3)
function sys=mdlUpdates(x,u,f,d)
f=f+1* x(3)*(x(2)-f*x(3))/(d+x(3)*x(3));
if f<=0.0001
    f=0.5;
end   
sys=[u(1);f;x(3)];
%Function mdlOutputs
%Output the current value of the counter(s).
function sys=mdlOutputs(t,x,u,c,d,f)
sys=1*c*f*x(1)/(1.1+f*f);%数字1代表的是λ 阶数越高 λ越大 但是λ调的过高会造成系统的延迟