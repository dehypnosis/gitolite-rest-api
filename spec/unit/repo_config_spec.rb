require_relative '../../lib/repo_config'

describe RepoConfig do
  let(:gitolite_admin_class_double) { double('admin') }
  let(:gitolite_ssh_key_class_double) { double('ssh_key') }
  let(:gitolite_group_class_double) { double('group') }
  let(:gitolite_repo_class_double) { double('repo') }
  let(:method_chain_double) { double('method_chain') }
  let(:hash) { Hash.new }
  let(:list) { Array.new }
  let(:user) { 'user' }
  let(:key_string) { 'key string' }
  let(:repo) { 'repo' }
  let(:group) { 'group' }
  let(:admin_path) { 'admin_path' }
  let(:permission) { 'RW+' }
  let(:string_empty) { '' }

  let(:repo_config) do
    RepoConfig.new(admin_path)
  end

  before do
    stub_const 'Gitolite::GitoliteAdmin', gitolite_admin_class_double
    stub_const 'Gitolite::Config::Group', gitolite_group_class_double
    stub_const 'Gitolite::Config::Repo', gitolite_repo_class_double
    stub_const 'Gitolite::SSHKey', gitolite_ssh_key_class_double

    gitolite_admin_class_double.should_receive(:new).with(admin_path).and_return(gitolite_admin_class_double)
  end

  it "should list users" do
    gitolite_admin_class_double.should_receive(:ssh_keys).and_return(hash)
    hash.should_receive(:keys).and_return(list)
    
    users = repo_config.users
    users.should be_an_instance_of(Array)
  end

  it "should list repos" do
    gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
    method_chain_double.should_receive(:repos).and_return(hash)
    hash.should_receive(:keys).and_return(list)

    repos = repo_config.repos
    repos.should be_an_instance_of(Array)
  end

  it "should list user groups" do
    hash = { "repo1" => gitolite_group_class_double, "repo2" => gitolite_group_class_double }
    gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
    method_chain_double.should_receive(:groups).and_return(hash)
    gitolite_group_class_double.should_receive(:users).twice.and_return(list)

    groups = repo_config.groups
    groups.should be_an_instance_of Hash
  end

  it "should add a new repo" do
    gitolite_repo_class_double.should_receive(:new).with(repo).and_return(gitolite_repo_class_double)
    gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
    method_chain_double.should_receive(:add_repo).with(gitolite_repo_class_double).and_return(true)
    gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

    repo_config.add_repo repo
  end

  it "should add a new user" do
    gitolite_ssh_key_class_double.should_receive(:from_string).with(key_string, user).and_return(gitolite_ssh_key_class_double)
    gitolite_admin_class_double.should_receive(:add_key).with(gitolite_ssh_key_class_double).and_return(true)
    gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

    repo_config.add_user(user, key_string)
  end

  describe ".remove_user" do
    context "user has one key" do
      it "should remove the key" do
        gitolite_admin_class_double.stub_chain(:ssh_keys, :[]).with(user).and_return(gitolite_ssh_key_class_double)
        gitolite_admin_class_double.should_receive(:rm_key).once.with(gitolite_ssh_key_class_double)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.remove_user user
      end
    end

    context "user has many keys" do
      it "should remove all keys" do
        gitolite_admin_class_double.stub_chain(:ssh_keys, :[]).with(user).and_return([gitolite_ssh_key_class_double, gitolite_ssh_key_class_double])
        gitolite_admin_class_double.should_receive(:rm_key).twice.with(gitolite_ssh_key_class_double)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.remove_user user
      end
    end
  end

  it "should remove a repo" do
    gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
    method_chain_double.should_receive(:rm_repo).with(repo).and_return(true)
    gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

    repo_config.remove_repo repo
  end

  describe ".add_group" do
    context "with no users passed as argument" do
      it "should create the group" do
        gitolite_group_class_double.should_receive(:new).with(group).and_return(gitolite_group_class_double)
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:groups).and_return(hash)
        hash.should_receive(:[]=).with(group, gitolite_group_class_double)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.add_group group
      end
    end

    context "with an array of users passed as parameter" do
      it "should create the group and add the users" do
        gitolite_group_class_double.should_receive(:new).with(group).and_return(gitolite_group_class_double)
        gitolite_group_class_double.should_receive(:users=).with(list)
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:groups).and_return(hash)
        hash.should_receive(:[]=).with(group, gitolite_group_class_double)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.add_group group, list
      end
    end
  end

  describe ".add_to_group" do
    context "when only one user is passed by param" do
      it "should add the user in the group" do
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:groups).and_return(hash)
        hash.should_receive(:[]).with(group).and_return(gitolite_group_class_double)
        gitolite_group_class_double.should_receive(:add_user).with(user)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.add_to_group user, group
      end
    end

    context "when many users are passed by param" do
      it "should add all the users in the group" do
        users = [user, user, user]
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:groups).and_return(hash)
        hash.should_receive(:[]).with(group).and_return(gitolite_group_class_double)
        gitolite_group_class_double.should_receive(:add_users).with(user, user, user)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.add_to_group users, group
      end
    end
  end

  describe ".remove_from_group" do
    context "when a single user is passed by param" do
      it "should remove the user from the group" do
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:groups).and_return(hash)
        hash.should_receive(:[]).with(group).and_return(gitolite_group_class_double)
        gitolite_group_class_double.should_receive(:rm_user).with(user)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.remove_from_group user, group
      end
    end

    context "when many users are passed by param" do
      it "should remove all users from the group" do
        users = [user, user, user]
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:groups).and_return(hash)
        hash.should_receive(:[]).with(group).and_return(gitolite_group_class_double)
        gitolite_group_class_double.should_receive(:rm_user).exactly(3).times.with(user)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.remove_from_group users, group
      end
    end
  end

  it "should be able to look for the user in a group" do
    gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
    method_chain_double.should_receive(:groups).and_return(hash)
    hash.should_receive(:[]).with(group).and_return(gitolite_group_class_double)
    gitolite_group_class_double.should_receive(:has_user?).with(user).and_return(true)

    result = repo_config.group_has_user? group, user
    result.should be_true
  end

  it "should be able to remove a group" do
    gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
    method_chain_double.should_receive(:groups).and_return(hash)
    hash.should_receive(:[]).with(group).and_return(gitolite_group_class_double)
    gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
    method_chain_double.should_receive(:rm_group).with(gitolite_group_class_double)
    gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

    repo_config.remove_group group
  end

  describe ".set_permission" do
    context "with one user passed as parameter" do
      it "should set the permission for that user in that repository" do
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:get_repo).with(repo).and_return(gitolite_repo_class_double)
        gitolite_repo_class_double.should_receive(:add_permission).with(permission, string_empty, user)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.set_permissions({ :user => user,  :repo => repo, :permissions => permission })
      end
    end

    context "with many users passed as parameter" do
      it "should set the permissions to all users passed as parameter" do
        users = [user, user, user]
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:get_repo).with(repo).and_return(gitolite_repo_class_double)
        gitolite_repo_class_double.should_receive(:add_permission).with(permission, string_empty, user, user, user)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.set_permissions({ :users => users,  :repo => repo, :permissions => permission })
      end
    end

    context "with a group passed as parameter" do
      it "should add the permission to all members of the group" do
        users = [user, user, user]
        gitolite_admin_class_double.should_receive(:config).and_return(method_chain_double)
        method_chain_double.should_receive(:get_repo).with(repo).and_return(gitolite_repo_class_double)

        gitolite_admin_class_double.stub_chain(:config, :groups, :[]).with(group).and_return(gitolite_group_class_double)
        gitolite_group_class_double.should_receive(:users).and_return(users)

        gitolite_repo_class_double.should_receive(:add_permission).with(permission, string_empty, user, user, user)
        gitolite_admin_class_double.should_receive(:save_and_apply).with(an_instance_of(String))

        repo_config.set_permissions({ :group => group, :permissions => permission, :repo => repo })
      end
    end
  end
end
