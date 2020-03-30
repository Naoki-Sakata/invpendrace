classdef robotsim
    %ROBOTSIM �V�~�����[�^�Ɛڑ����邽�߂̃N���X
    %   �V�~�����[�^�Ɛڑ����邽�߂̃N���X�D
    
    properties
        baseurl
    end
    
    methods
        function obj = robotsim(baseurl)
            %ROBOT ���̃N���X�̃C���X�^���X���쐬
            %   baseurl�ɐڑ���̃V�~�����[�^�̊��URL���w�肷��D
            %   ����PC�̃V�~�����[�^�ɂ��ڑ��ł���͂�
            obj.baseurl = baseurl;
        end
        function [] = reset(obj)
            %RESET �V�~�����[�^�����Z�b�g����D
            %   ���E�ƑS�Ẵ��{�b�g���폜���C�V���Ȑ��E�𐶐�����
            py.requests.post([obj.baseurl,'reset'],pyargs('data',{}));
        end
        function id = spawn(obj, p)
            %SPAWN ���{�b�g��V���ɐ�������
            %   �������ꂽ���{�b�g���ʂ��邽�߂�ID��Ԃ�
            data = struct();
            if nargin>=2
                data.p = p;
            end
            res = py.requests.post([obj.baseurl,'spawn'],pyargs('data',data));
            res = jsondecode(char(res.text));
            id = string(res.id);
        end
        
        function state = wait(obj, id)
            %WAIT ���{�b�g��ҋ@��Ԃňێ������܂܃V�~�����[�^��1�����i�߂�
            %   ������Ԃł̓��{�b�g�̊֐߂����_�ɂ���̂Ŋ֐߂̂΂˂��g����
            %   ����ȏ�ԂɂȂ�̂�҂��߂����̊֐�
            data = struct('id',id,'u',[0,0,0], 'doControl', false);
      
            res = py.requests.post([obj.baseurl,'control'],pyargs('data',data));
            state = jsondecode(char(res.text));
        end
        
        function state = control(obj, id, u, info)
            %CONTROL ���{�b�g�̏�Ԃ��擾���C������͂��������
            %   �V�~�����[�^�͂��̃R�}���h���󂯎�������_�ł̃��{�b�g�̏�Ԃ�Ԃ�
            %   ���̌�w�肵��������͂̂��Ƃ�1�X�e�b�v������i�߂�D
            %   ��ԂƐ�����͂̎��ԍ��ɒ��ӂ��邱��
            %   control �� wait �����s����Ȃ�����V�~�����[�^�̎��Ԃ͒�~�����܂܂ł���D
            %   �܂�C���̊֐��̌Ăяo���p�x�ɂ���ăV�~�����[�^�̎��Ԃ������Ԃɑ΂���
            %   ���������茸�������肷�邱�Ƃ��ł���D����̓f�o�b�O�̂��߂ɗL�p�ł���D
            
            
            data = struct('id',id,'u',u, 'doControl', true);
            if nargin>=4
                data.info = info;
            end
            res = py.requests.post([obj.baseurl,'control'],pyargs('data',data));
            state = jsondecode(char(res.text));
        end
        function res = screenshot(obj)
            res = webread([obj.baseurl,'screenshot']);
        end
    end
end

