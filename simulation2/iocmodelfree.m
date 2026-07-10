
function [sys,x0,str,ts]=iocmodelfree(t,x,u,flag,c,d,f)%c是ρ d是μf是fai
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
 error(['Unhandled flag=',num2str(flag)]);
end
%Function:mdlInitializeSizes.
%S-function running with period of 1 second
%Number of inputs is 3(discstates).
%The number of output is 1.
%Passed in to the S-function.
function [sys,x0,str,ts]=mdlInitializeSizes
sizes=simsizes;
sizes.NumContStates=0; %设置系统连续状态的数量
sizes.NumDiscStates=4;%设置系统离散状态的数量
sizes.NumOutputs=1; %设置系统输出的数量
sizes.NumInputs=4;%设置系统输入的数量
sizes.DirFeedthrough=1;%设置系统直接通过量的数量，一般为1
sizes.NumSampleTimes=1;% at least one sample time is needed
                            % 需要的样本时间，一般为1.
                            % 猜测为如果为n，则下一时刻的状态需要知道前n个状态的系统状态
sys=simsizes(sizes);
x0=[0,0,0,0];
str=[];
ts=[0.1 0];
%Function:mdlUpdates
%Each state by the amount specified in the vararg inputs.
%Where x(1)=u(1)=e(1),x(2)=u(2)=f,x(3)=u(3)
function sys=mdlUpdates(x,u,f,d)
f=f+1*x(3)*(x(2)-f*x(3))/(d+x(3)*x(3));
if f<0.001||u(4)<0
f=0.5;
end   
sys=[u(1);f;x(3);1];
%Function mdlOutputs
%Output the current value of the counter(s).
function sys=mdlOutputs(t,x,u,c,d,f)
if u(1)<=u(4)
    sys=1*c*f*u(1)/(1+f*f);
else
    sys=1*c*f*u(1)*3*u(4)/(1+f*f);
end