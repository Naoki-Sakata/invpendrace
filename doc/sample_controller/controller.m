%% �I�t���C���ȏ����i����n�݌v�j
mb = 3;
mw = 1;
r = 0.2;

Ib = 1/3*mb*(0.3^2+0.2^2);
Iw = 1/2*mw*r^2;
g=9.8;

A = [zeros(4),eye(4);
    zeros(3,8);
    zeros(1,7),-4*mb*g/(Iw+r^2*mw)];

h = 1;

B = [zeros(4,3);
    diag([1/mb,1/mb,1/Ib]);
    -1/mb-r/(Iw+r^2*mw)*(r+h),0,r/(Iw+r^2*mw)];

Q = diag([100,100,100,10, 1, 0.1, 1,10000]);
R = diag([1, 0.01, 1]);

K = zeros(3,8);

% �Ȃ񂩐��l�I�ɂ�΂��݂����Ȃ̂�y�Ƃ��̑��ɂ킯�Đ݌v
idx = [1,1,0,1,1,1,0,1]==1;
K(:,idx) = lqr( A(idx,idx),B(idx,:),Q(idx,idx),R); % y�ȊO
K(:,~idx) = lqr(A(~idx,~idx),B(~idx,:),Q(~idx,~idx),R); % y

%% ��������I�����C��
rs = robotsim('http://localhost:8933/api/');

rs.reset()

p0 = [0,2];

id = rs.spawn(p0); % ���{�b�g�̏o���ʒu�͕ς�����

% �蔲���̂��߃��{�b�g�͏�Ɏ��_�Ő�������邪
% ���䂪�J�n�����܂ł͊֐߂Ɏ��_����E�o���邽�߂�
% ����Ȃ΂˗͂������Ă���D
% �����̌��ʂ�������Ƒ҂K�v������D����
for k=1:20
    state = rs.wait(id);
end

dt=1/60;

% �L�^�p�̍s����m��
nx = 8;
U = zeros(3,1000*60)*nan;
X = zeros(nx,1000*60)*nan;

step = 1;
t=0;

mode = 'init';

recordMovie = false; % ��������Ƃ��� false �� true ��

if recordMovie
    if exist('video','var') %#ok<UNRCH>
        close(video)
    end
    video = VideoWriter('record','MPEG-4');
    video.Quality = 95;
    video.FrameRate = 60;
    open(video)
end

while true
    tic
    x = [state.body.position.x;
        state.body.position.y-state.wheel.position.y -  h;
        state.body.angle;
        state.wheel.position.x-state.body.position.x;
        state.body.velocity.x;
        state.body.velocity.y-state.wheel.velocity.y;
        state.body.angularVelocity;
        state.wheel.velocity.x- state.body.velocity.x];
    
    % ���[�h�J�ڑ�
    switch mode
        case 'init'
            ref = x(1);
            if t>3
                mode = 'run';
                jumped_1 = false;
                jumped_2 = false;
            end
        case 'run'
            if x(1)>48.5 && jumped_1 == false
                mode = 'jump';
                jumped_1 = true;
                tj = t;
            end
            if x(1)>82.5 && jumped_2 == false
                mode = 'jump';
                jumped_2 = true;
                tj = t;
            end
            if x(1) > 165
                mode = 'end';
                te = t;
            end
        case 'jump'
            if t-tj>1/4
                mode = 'run';
            end
        case 'end'
            if t-te>5
                mode = 'exit';
            end
    end
    
    
    % ���䑥
    
    if strcmp(mode,'run') || strcmp(mode,'jump')
        v = 5;
    else
        v = 0;
    end
    
    x(1) = x(1)-ref;
    x(5) = x(5)-v;
    ref = ref+v*dt;
    
    if strcmp(mode,'jump')
        x(2) = x(2) - 0.5*abs(sin((t-tj)*pi*4));
        x(6) = x(6) - 0.5*sign(sin((t-tj)*pi*4))*cos((t-tj)*pi*1)*pi*4;
    end
    
    u = -K*x;
    u(2) = u(2)+mb*g;
    
    % �n�ʂ��犮�S�ɗ��ꂽ��Ƃ肠�����E��
    if state.numLandContacts == 0
        u = zeros(3,1);
    end
    
    % �L�^
    X(:,step) = x;
    U(:,step) = u;
    
    % �f�o�b�O�p�ɃV�~�����[�^�ɕ\�����邱�Ƃ��ł���
    if strcmp(mode,'init')
        info = '�������܁`���I';
    elseif strcmp(mode, 'jump')
        info = '������I';
    elseif strcmp(mode, 'end')
        info = '����ꂾ���E�E�E';
    else
        info = '';
    end
    
    state = rs.control(id,u,info);
    
    if recordMovie
        writeVideo(video,rs.screenshot()); %#ok<UNRCH>
    end
    % �V�~�����[�^���Ԃ������ԂƓ����y�[�X�Ōo�߂���悤�ɑ҂�
    % �҂��Ȃ���΃��A���e�B�͎����邪�����͑����I���
    rdt = toc;
    if rdt<dt
        pause(dt-rdt)
    end
    
    if strcmp(mode,'exit')
        break
    end
    t=t+dt;
    step=step+1;
end

%% ������̏���
X(:,step+1:end)=[]; % �]��������������
U(:,step+1:end)=[];
T = dt*(1:step);
figure(1)
clf
axs = [];
for l=1:nx
    subplot(nx,1,l)
    plot(T,X(l,:))
    xlim(T([1,end]))
    axs(end+1) = gca; %#ok<SAGROW>
end
linkaxes(axs,'x')

figure(2)
clf
axs = [];
for l=1:3
    subplot(3,1,l)
    plot(T,U(l,:))
    xlim(T([1,end]))
    axs(end+1) = gca; %#ok<SAGROW>
end
linkaxes(axs,'x')

if recordMovie
    close(video) %#ok<UNRCH>
end

