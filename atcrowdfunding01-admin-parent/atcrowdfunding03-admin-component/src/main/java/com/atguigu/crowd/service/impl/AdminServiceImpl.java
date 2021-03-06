package com.atguigu.crowd.service.impl;

import com.atguigu.crowd.entity.AdminEntity;
import com.atguigu.crowd.mapper.AdminMapper;
import com.atguigu.crowd.service.AdminService;
import com.atguigu.crowd.util.CrowdUtil;
import com.atguigu.crowd.util.constant.CrowConst;
import com.atguigu.crowd.util.exception.LoginAcctAlreadyExistsException;
import com.atguigu.crowd.util.exception.LoginFailedException;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.CollectionUtils;
import org.springframework.util.StringUtils;

import java.util.List;


/**
 * <p>
 * 管理员账户表 服务实现类
 * </p>
 *
 * @author zhuyc
 * @since 2020-04-14
 */
@Slf4j
@Service
public class AdminServiceImpl extends ServiceImpl<AdminMapper, AdminEntity> implements AdminService {

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public AdminEntity doLogin(String username, String password) {

        AdminEntity entity = this.getOne(
                new LambdaQueryWrapper<AdminEntity>().eq(AdminEntity::getLoginAcct, username)
        );

        if (entity == null) {
            throw new LoginFailedException(CrowConst.MSG_ACCT_NOT_EXIST);
        }

        String encoding = CrowdUtil.md5Encoding(password);

        if (!encoding.equals(entity.getUserPswd())) {
            throw new LoginFailedException(CrowConst.MSG_PASSWORD_ERROR);
        }
        entity.setUserPswd(null);
        return entity;
    }

    @Override
    public Page<AdminEntity> getPageInfo(String keyword, Integer pageNum, Integer pageSize) {
        LambdaQueryWrapper<AdminEntity> wrapper = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            wrapper.like(AdminEntity::getLoginAcct, keyword)
                    .or()
                    .like(AdminEntity::getUserName, keyword)
                    .or()
                    .like(AdminEntity::getEmail, keyword);
        }
        wrapper.select(AdminEntity::getId, AdminEntity::getLoginAcct, AdminEntity::getUserName, AdminEntity::getEmail, AdminEntity::getCreateTime);
        return this.page(new Page<>(pageNum, pageSize), wrapper);
    }

    @Override
    public void saveAdmin(AdminEntity entity) {
//        entity.setUserPswd(CrowdUtil.md5Encoding(entity.getUserPswd()));
        entity.setUserPswd(passwordEncoder.encode(entity.getUserPswd()));
        try {
            this.save(entity);
        } catch (DuplicateKeyException e) {
            throw new LoginAcctAlreadyExistsException("抱歉,账号已经被注册");
        }
    }

    @Override
    public void modifyAdmin(AdminEntity entity) {
        entity.setLoginAcct(null).setUserPswd(null).setCreateTime(null);
        this.updateById(entity);
    }

    @Transactional(rollbackFor = Exception.class)
    @Override
    public void saveAdminRoleRelationship(Integer id, List<Integer> roleList) {
        this.baseMapper.deleteRelationship(id);
        if (!CollectionUtils.isEmpty(roleList)) {
            this.baseMapper.insertRelationship(id, roleList);
        }
    }

    @Override
    public AdminEntity getByUsername(String username) {
        return this.getOne(
                new LambdaQueryWrapper<AdminEntity>().eq(AdminEntity::getLoginAcct, username)
        );
    }
}
